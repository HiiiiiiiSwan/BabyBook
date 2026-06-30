import Foundation

// MARK: - 网络服务
class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - 通用请求方法
    func request<T: Codable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var url = endpoint.url else {
            throw APIError.invalidURL
        }

        // 添加查询参数
        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            components?.queryItems = queryItems
            if let finalURL = components?.url {
                url = finalURL
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 添加设备认证头
        request.setValue(DeviceService.shared.deviceId, forHTTPHeaderField: "X-Device-Id")

        // 添加请求体
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // 检查 HTTP 状态码
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw APIError.httpError(httpResponse.statusCode, errorMessage)
        }

        // 解析响应数据
        do {
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - 下载文件
    func downloadFile(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return data
    }

    // MARK: - 创建订单
    func createOrder(bookId: String, deviceId: String, imageUrl: String? = nil) async throws -> BackendOrder {
        let requestBody = CreateOrderRequest(
            bookId: bookId,
            deviceId: deviceId,
            imageUrl: imageUrl
        )
        return try await request(endpoint: .createOrder, body: requestBody)
    }

    // MARK: - 查询订单详情
    func getOrder(orderId: String) async throws -> BackendOrder {
        return try await request(endpoint: .getOrder(orderId))
    }

    // MARK: - 查询订单列表
    func listOrders(deviceId: String? = nil, status: String? = nil, page: Int = 1, limit: Int = 10) async throws -> OrderListResponse {
        var queryItems: [URLQueryItem] = []
        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "deviceId", value: deviceId))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))

        return try await request(endpoint: .listOrders, queryItems: queryItems)
    }

    // MARK: - 验证支付
    func verifyPayment(orderId: String, receiptData: String, transactionId: String, imageUrl: String? = nil) async throws -> PaymentVerifyResponse {
        let requestBody = VerifyPaymentRequest(
            orderId: orderId,
            receiptData: receiptData,
            transactionId: transactionId,
            imageUrl: imageUrl
        )
        return try await request(endpoint: .verifyPayment, body: requestBody)
    }

    // MARK: - 查询任务状态
    func getTask(taskId: String) async throws -> BackendTask {
        return try await request(endpoint: .getTask(taskId))
    }

    // MARK: - 根据订单ID查询任务
    func getTaskByOrderId(orderId: String) async throws -> BackendTask? {
        do {
            return try await request(endpoint: .getTaskByOrder(orderId))
        } catch let error as APIError {
            if case .httpError(404, _) = error {
                return nil
            }
            throw error
        }
    }

    // MARK: - 取消任务
    func cancelTask(taskId: String) async throws {
        let _: [String: String] = try await request(endpoint: .cancelTask(taskId))
    }

    // MARK: - 获取绘本下载信息
    func getBookDownloadInfo(orderId: String) async throws -> BookDownloadResponse {
        return try await request(endpoint: .downloadBook(orderId))
    }

    // MARK: - 更新订单图片 URL
    func updateOrderImage(orderId: String, imageUrl: String) async throws {
        let requestBody = UpdateOrderImageRequest(imageUrl: imageUrl)
        let _: [String: String] = try await request(endpoint: .updateOrderImage(orderId), body: requestBody)
    }

    // MARK: - 下载绘本图片
    func downloadBookImage(orderId: String) async throws -> Data {
        guard let url = APIEndpoint.downloadBookImage(orderId).url else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return data
    }
}
