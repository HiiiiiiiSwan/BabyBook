import Foundation
import StoreKit

// MARK: - 支付相关通知
extension Notification.Name {
    static let orderPaymentRestored = Notification.Name("orderPaymentRestored")
}

// MARK: - StoreKit2 支付服务
@MainActor
class PaymentService: ObservableObject {
    static let shared = PaymentService()

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 产品 ID 映射（与 App Store Connect 中配置的一致）
    let productIDs = [
        "com.shihui.babybook.book001",  // 《这是我》
        "com.shihui.babybook.book002",  // 《我长大想做什么》
        "com.shihui.babybook.book003",  // 《认识颜色》
    ]

    // 绘本 ID 到产品 ID 的映射
    private let bookToProductMap: [String: String] = [
        "Book001": "com.shihui.babybook.book001",
        "Book002": "com.shihui.babybook.book002",
        "Book003": "com.shihui.babybook.book003",
    ]

    private init() {}

    // MARK: - 加载产品
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: Set(productIDs))
            self.products = products.sorted { $0.price < $1.price }
            print("成功加载 \(products.count) 个产品")
        } catch {
            errorMessage = "加载产品失败: \(error.localizedDescription)"
            print("加载产品失败: \(error)")
        }
    }

    // MARK: - 获取产品（根据绘本 ID）
    func product(for bookId: String) -> Product? {
        guard let productID = bookToProductMap[bookId] else { return nil }
        return products.first { $0.id == productID }
    }

    // MARK: - 购买产品
    func purchase(bookId: String, orderId: String) async throws -> Transaction {
        try await purchase(bookId: bookId, orderId: orderId, attempt: 1)
    }

    /// 购买实现（带重试计数）。
    /// 沙盒环境下，上一次未 finish 的交易会被 StoreKit 复用——本次 purchase 可能拿到的
    /// 不是新交易，而是一笔绑定了旧订单的历史交易。若直接用当前订单号去验证，会撞后端
    /// paymentId 唯一校验（400 "该交易已完成支付"）。因此这里校验交易归属，发现旧交易
    /// 就先结算清理再重试，确保最终用一笔真正属于当前订单的干净交易完成验证。
    private func purchase(bookId: String, orderId: String, attempt: Int) async throws -> Transaction {
        guard let product = product(for: bookId) else {
            throw PaymentError.productNotFound
        }

        // 校验商品类型必须为 Consumable（消耗型）
        guard product.type == .consumable else {
            throw PaymentError.productNotConsumable
        }

        // 【关键】把订单 ID 作为 appAccountToken 附到交易上，
        // 这样交易与订单形成可靠绑定。后续 Transaction.updates 重放该交易时，
        // 能从 transaction.appAccountToken 读回真正配对的订单，
        // 而不是错误地去顶「本地最后一个订单」，避免一笔交易污染多个订单。
        let orderUUID = UUID(uuidString: orderId)
        var purchaseOptions: Set<Product.PurchaseOption> = []
        if let orderUUID = orderUUID {
            purchaseOptions.insert(.appAccountToken(orderUUID))
        }

        // 开始购买流程
        let result = try await product.purchase(options: purchaseOptions)

        switch result {
        case .success(let verification):
            // 先提取 StoreKit2 JWS 收据（必须在 checkVerified 之前，因为 jwsRepresentation 在 VerificationResult 上）
            let receiptData = verification.jwsRepresentation

            // 验证交易
            let transaction = try checkVerified(verification)

            // 【诊断】无条件打印本次拿到的交易详情，用于定位沙盒复用旧交易问题
            print("[购买诊断] 当前订单=\(orderId) 合法UUID=\(orderUUID != nil) | 交易id=\(transaction.id) originalId=\(transaction.originalID) 交易绑定token=\(transaction.appAccountToken?.uuidString.lowercased() ?? "nil")")

            // 【防沙盒复用旧交易】只要本次确实绑定了 token（orderId 是合法 UUID），
            // 就校验拿到的交易是否真属于当前订单：
            // - 交易带的 token ≠ 当前订单：StoreKit 返回了别的订单的旧交易，
            //   先用它自己的订单把它结算掉并 finish，再重试当前订单的购买；
            // - 交易没有 token：本次一定带了 token，却拿到无 token 交易，必是历史旧交易，
            //   直接 finish 丢弃再重试。
            // 这样避免用旧交易的 transactionId 去撞当前订单，触发后端 400。
            if orderUUID != nil {
                if let token = transaction.appAccountToken {
                    if token != orderUUID {
                        let staleOrderId = token.uuidString.lowercased()
                        print("购买返回了旧交易（绑定订单 \(staleOrderId)，transactionId=\(transaction.id)），非当前订单 \(orderId)，清理后重试")
                        // 用旧交易自身绑定的订单去结算（幂等；失败也无妨），随后 finish 清理
                        try? await verifyPaymentWithBackend(
                            transaction: transaction,
                            receiptData: receiptData,
                            orderId: staleOrderId
                        )
                        await transaction.finish()
                        return try await retryPurchaseAfterCleanup(bookId: bookId, orderId: orderId, attempt: attempt)
                    }
                } else {
                    print("购买返回了无绑定 token 的旧交易（transactionId=\(transaction.id)），finish 丢弃后重试")
                    await transaction.finish()
                    return try await retryPurchaseAfterCleanup(bookId: bookId, orderId: orderId, attempt: attempt)
                }
            }

            // 先向后端验证支付，确认服务端已收到并创建生成任务后，
            // 再 finish 交易。避免 Apple 已扣款但后端未确认时交易被关闭。
            try await verifyPaymentWithBackend(
                transaction: transaction,
                receiptData: receiptData,
                orderId: orderId
            )

            // 后端验证成功后，再 finish 交易，防止 StoreKit 重复推送
            await transaction.finish()

            return transaction

        case .userCancelled:
            throw PaymentError.userCancelled

        case .pending:
            throw PaymentError.pending

        @unknown default:
            throw PaymentError.unknown
        }
    }

    /// 清理旧交易后重试购买；超过重试上限则抛出可提示用户的错误。
    private func retryPurchaseAfterCleanup(bookId: String, orderId: String, attempt: Int) async throws -> Transaction {
        guard attempt < 3 else {
            throw PaymentError.paidButServerError("支付交易异常，请稍后重试或联系客服")
        }
        return try await purchase(bookId: bookId, orderId: orderId, attempt: attempt + 1)
    }

    // MARK: - 验证交易
    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            throw error
        }
    }

    // MARK: - 向后端验证支付
    private func verifyPaymentWithBackend(
        transaction: Transaction,
        receiptData: String,
        orderId: String
    ) async throws {
        #if os(iOS)
        #if targetEnvironment(simulator)
        // 模拟器环境：跳过实际的 StoreKit 验证，使用模拟收据
        print("模拟器环境：跳过 StoreKit 验证，使用模拟收据")
        let finalReceiptData = "simulator_receipt_\(transaction.id)"
        let transactionId = String(transaction.id)

        do {
            let response = try await NetworkService.shared.verifyPayment(
                orderId: orderId,
                receiptData: finalReceiptData,
                transactionId: transactionId
            )

            guard response.success else {
                throw PaymentError.paidButServerError(response.errorMessage ?? "支付验证失败")
            }
        } catch is APIError, is URLError {
            // Apple 已扣款（模拟器视为已扣款），但后端网络异常
            throw PaymentError.paidButServerError("服务器连接异常，请稍后重试或联系客服")
        }
        #else
        // 真机环境：使用从 VerificationResult 提取的 JWS 收据
        let transactionId = String(transaction.id)

        // 调用后端验证接口
        do {
            let response = try await NetworkService.shared.verifyPayment(
                orderId: orderId,
                receiptData: receiptData,
                transactionId: transactionId
            )

            guard response.success else {
                throw PaymentError.paidButServerError(response.errorMessage ?? "支付验证失败")
            }
        } catch let error as APIError {
            // Apple 已扣款，但后端返回错误：打印真实原因以定位（401/400/500 等）
            print("[支付验证失败-后端错误] \(error.localizedDescription)")
            // 后端 400 且明确是「交易重复/订单状态不正确」时，透传真实文案。
            // 这类错误用于恢复流程判定该交易应被 finish 丢弃（见 handleUnfinishedTransaction），
            // 正常购买流程的失败页用的是写死文案，不受影响。
            if case .httpError(400, let body) = error,
               body.contains("重复") || body.contains("已完成支付") || body.contains("状态不正确") {
                throw PaymentError.paidButServerError(body)
            }
            throw PaymentError.paidButServerError("服务器连接异常，请稍后重试或联系客服")
        } catch let error as URLError {
            print("[支付验证失败-网络错误] code=\(error.code.rawValue) \(error.localizedDescription)")
            throw PaymentError.paidButServerError("服务器连接异常，请稍后重试或联系客服")
        }
        #endif
        #endif
    }

    // MARK: - 恢复购买
    func restorePurchases() async throws {
        for await entitlement in Transaction.currentEntitlements {
            let transaction = try checkVerified(entitlement)
            print("恢复购买: \(transaction.productID)")
        }
    }

    // MARK: - 监听交易更新
    func listenForTransactions() {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try checkVerified(verificationResult)

                    // 检查交易是否已完成验证
                    var shouldFinish = true
                    if transaction.revocationDate == nil {
                        // 从未完成的交易恢复：提取 orderId 并验证
                        shouldFinish = await handleUnfinishedTransaction(transaction)
                    }

                    // 只有验证成功或已撤销/退款等无需恢复的交易才 finish
                    if shouldFinish {
                        await transaction.finish()
                    }
                } catch {
                    print("交易更新处理失败: \(error)")
                }
            }
        }
    }

    // MARK: - 处理未完成的交易（App 崩溃/杀后台后恢复）
    private func handleUnfinishedTransaction(_ transaction: Transaction) async -> Bool {
        // 【关键】只处理与订单可靠绑定的交易：从交易自带的 appAccountToken 读回订单 ID。
        // 购买时通过 .appAccountToken(orderUUID) 写入，这里才能读回。
        //
        // 若 appAccountToken 为空，说明这是一笔无法与订单配对的孤儿交易
        // （例如历史沙盒遗留的交易、或旧版本未绑定 token 的交易）。
        // 这类交易绝不能拿去顶「本地最后一个订单」——那会把它的 transactionId
        // 写进一个不相干的新订单，撞后端 paymentId 唯一校验并污染新订单。
        // 正确做法：直接 finish 丢弃，终止 StoreKit 的无限重放。
        guard let orderToken = transaction.appAccountToken else {
            print("未绑定订单的孤儿交易（transactionId=\(transaction.id)），直接 finish 丢弃，避免污染新订单")
            return true
        }

        let orderId = orderToken.uuidString.lowercased()
        print("发现未完成的交易，绑定订单: \(orderId)")

        do {
            // 向后端验证支付
            // 注意：恢复交易时无法获取原始 VerificationResult 的 jwsRepresentation
            // 这里使用 transactionId 作为收据占位符，后端开发环境会特殊处理
            try await verifyPaymentWithBackend(
                transaction: transaction,
                receiptData: "restored_\(transaction.id)",
                orderId: orderId
            )

            // 验证成功，通知恢复订单
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .orderPaymentRestored,
                    object: orderId
                )
            }
            return true
        } catch PaymentError.paidButServerError(let message) where message.contains("重复") || message.contains("状态不正确") {
            // 后端明确判定该交易已完成/订单状态不正确：说明这笔交易已无需再处理，
            // 继续保留只会每次启动都重放报错。直接 finish 丢弃。
            print("交易已被后端确认处理过（\(message)），finish 丢弃")
            return true
        } catch {
            print("恢复交易验证失败: \(error)")
            // 其他错误（如网络异常）不 finish，让 StoreKit 下次继续推送，便于重试
            return false
        }
    }
}

// MARK: - 支付错误
enum PaymentError: Error, LocalizedError {
    case productNotFound
    case productNotConsumable
    case userCancelled
    case pending
    case unknown
    case verificationFailed(String)
    case paidButServerError(String)  // Apple 已扣款，但后端验证/任务创建失败

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "产品未找到"
        case .productNotConsumable:
            return "商品类型配置错误，请稍后再试"
        case .userCancelled:
            return "用户取消支付"
        case .pending:
            return "支付等待中"
        case .unknown:
            return "未知错误"
        case .verificationFailed(let message):
            return "验证失败: \(message)"
        case .paidButServerError(let message):
            return "支付成功但服务器异常: \(message)"
        }
    }
}
