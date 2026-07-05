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
        guard let product = product(for: bookId) else {
            throw PaymentError.productNotFound
        }

        // 校验商品类型必须为 Consumable（消耗型）
        guard product.type == .consumable else {
            throw PaymentError.productNotConsumable
        }

        // 开始购买流程
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // 先提取 StoreKit2 JWS 收据（必须在 checkVerified 之前，因为 jwsRepresentation 在 VerificationResult 上）
            let receiptData = verification.jwsRepresentation

            // 验证交易
            let transaction = try checkVerified(verification)

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
        } catch is APIError, is URLError {
            // Apple 已扣款，但后端验证网络异常
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
        // 从交易备注中提取 orderId（如果购买时存储了）
        // StoreKit2 不直接支持自定义 payload，我们通过本地存储关联

        // 查询本地是否有待验证的订单
        if let pendingOrderId = OrderStatusManager.shared.loadPendingOrderId() {
            print("发现未完成的交易，关联订单: \(pendingOrderId)")

            do {
                // 向后端验证支付
                // 注意：恢复交易时无法获取原始 VerificationResult 的 jwsRepresentation
                // 这里使用 transactionId 作为收据占位符，后端开发环境会特殊处理
                try await verifyPaymentWithBackend(
                    transaction: transaction,
                    receiptData: "restored_\(transaction.id)",
                    orderId: pendingOrderId
                )

                // 验证成功，通知恢复订单
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .orderPaymentRestored,
                        object: pendingOrderId
                    )
                }
                return true
            } catch {
                print("恢复交易验证失败: \(error)")
                // 验证失败时不 finish，让 StoreKit 下次继续推送，便于重试
                return false
            }
        }
        return true
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
