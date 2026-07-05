import Foundation

// MARK: - API 配置
enum APIConfig {
    // 环境切换开关
    enum Environment {
        case local        // 本地开发
        case lan          // 局域网真机测试
        case staging      // 预发布环境
        case production   // 生产环境
    }

    // 当前环境（修改此处切换）
    static let current: Environment = .lan

    // 后端服务地址
    static var baseURL: String {
        switch current {
        case .local:
            return "http://localhost:3000"
        case .lan:
            // 替换为你的局域网 IP
            return "http://192.168.0.28:3000"
        case .staging:
            return "https://staging-api.babybook.com"
        case .production:
            return "https://your-railway-app.railway.app"
        }
    }

    // API 路径前缀
    static let apiPrefix = "/api"

    // 完整基础 URL
    static var fullBaseURL: String {
        return baseURL + apiPrefix
    }

    // 超时配置
    static let requestTimeout: TimeInterval = 30
    static let uploadTimeout: TimeInterval = 60

    // 是否使用 Mock 数据（不连接后端）
    static let useMockData = false

    // 是否打印请求日志
    static let enableLogging = true
}

// MARK: - API 端点
enum APIEndpoint {
    case createOrder          // POST /order/create
    case healthCheck          // GET /health
    case getOrder(String)     // GET /order/:id
    case listOrders           // GET /order
    case verifyPayment        // POST /payment/verify
    case getTask(String)      // GET /task/:id
    case getTaskByOrder(String) // GET /task/order/:orderId
    case cancelTask(String)   // POST /task/:id/cancel
    case downloadBook(String) // GET /book/:orderId/download
    case downloadBookImage(String) // GET /book/:orderId/image
    case updateOrderImage(String) // POST /order/:id/image

    var path: String {
        switch self {
        case .createOrder:
            return "/order/create"
        case .healthCheck:
            return "/health"
        case .getOrder(let id):
            return "/order/\(id)"
        case .listOrders:
            return "/order"
        case .verifyPayment:
            return "/payment/verify"
        case .getTask(let id):
            return "/task/\(id)"
        case .getTaskByOrder(let orderId):
            return "/task/order/\(orderId)"
        case .cancelTask(let id):
            return "/task/\(id)/cancel"
        case .downloadBook(let orderId):
            return "/book/\(orderId)/download"
        case .downloadBookImage(let orderId):
            return "/book/\(orderId)/image"
        case .updateOrderImage(let orderId):
            return "/order/\(orderId)/image"
        }
    }

    var url: URL? {
        return URL(string: APIConfig.fullBaseURL + path)
    }

    var method: String {
        switch self {
        case .createOrder, .verifyPayment, .cancelTask, .updateOrderImage:
            return "POST"
        case .healthCheck, .getOrder, .listOrders, .getTask, .getTaskByOrder, .downloadBook, .downloadBookImage:
            return "GET"
        }
    }
}

// MARK: - API 错误
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    case noData
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code, let message):
            return "HTTP 错误 \(code): \(message)"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .noData:
            return "没有返回数据"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

// MARK: - API 响应模型
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: Int
}

// MARK: - 请求模型
struct CreateOrderRequest: Codable {
    let bookId: String
    let deviceId: String
    let imageUrl: String?
}

struct VerifyPaymentRequest: Codable {
    let orderId: String
    let receiptData: String
    let transactionId: String
    let imageUrl: String?
}

struct UpdateOrderImageRequest: Codable {
    let imageUrl: String
}
