import Foundation
import StoreKit

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

        // 开始购买流程
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // 验证交易
            let transaction = try checkVerified(verification)

            // 验证支付并提交到后端
            try await verifyPaymentWithBackend(transaction: transaction, orderId: orderId)

            // 完成交易
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
    private func verifyPaymentWithBackend(transaction: Transaction, orderId: String) async throws {
        #if os(iOS)
        #if targetEnvironment(simulator)
        // 模拟器环境：跳过实际的 StoreKit 验证，使用模拟收据
        print("模拟器环境：跳过 StoreKit 验证，使用模拟收据")
        let receiptData = "simulator_receipt_\(transaction.id)"
        let transactionId = String(transaction.id)

        let response = try await NetworkService.shared.verifyPayment(
            orderId: orderId,
            receiptData: receiptData,
            transactionId: transactionId
        )

        guard response.success else {
            throw PaymentError.verificationFailed(response.errorMessage ?? "支付验证失败")
        }
        #else
        // 真机环境：获取收据数据（StoreKit2 使用 jwsRepresentation）
        let receiptData = transaction.jwsRepresentation
        let transactionId = String(transaction.id)

        // 调用后端验证接口
        let response = try await NetworkService.shared.verifyPayment(
            orderId: orderId,
            receiptData: receiptData,
            transactionId: transactionId
        )

        guard response.success else {
            throw PaymentError.verificationFailed(response.errorMessage ?? "支付验证失败")
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
                    // 处理未完成的交易
                    await transaction.finish()
                } catch {
                    print("交易更新处理失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 支付错误
enum PaymentError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unknown
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "产品未找到"
        case .userCancelled:
            return "用户取消支付"
        case .pending:
            return "支付等待中"
        case .unknown:
            return "未知错误"
        case .verificationFailed(let message):
            return "验证失败: \(message)"
        }
    }
}
