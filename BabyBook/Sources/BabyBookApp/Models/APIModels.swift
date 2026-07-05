import Foundation

// MARK: - 后端订单模型（与 NestJS 后端对应）
struct BackendOrder: Codable, Identifiable {
    let id: String
    let deviceId: String
    let bookId: String
    let bookName: String
    let amount: Double
    let status: String
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId
        case bookId
        case bookName
        case amount
        case status
        case createdAt
        case updatedAt
    }
}

extension BackendOrder {
    /// 返回一个状态被更新后的新订单（struct 不可变，需要复制）
    func updatingStatus(to newStatus: String) -> BackendOrder {
        return BackendOrder(
            id: id,
            deviceId: deviceId,
            bookId: bookId,
            bookName: bookName,
            amount: amount,
            status: newStatus,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - 后端任务模型
struct BackendTask: Codable, Identifiable {
    let id: String
    let orderId: String
    let status: String
    let progress: Int
    let resultUrl: String?
    let errorMessage: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId
        case status
        case progress
        case resultUrl
        case errorMessage
        case createdAt
        case updatedAt
    }
}

// MARK: - 订单列表响应
struct OrderListResponse: Codable {
    let orders: [BackendOrder]
    let total: Int
}

// MARK: - 支付验证响应
struct PaymentVerifyResponse: Codable {
    let success: Bool
    let orderId: String
    let status: String
    let errorMessage: String?
}

// MARK: - 绘本下载信息响应
struct BookDownloadResponse: Codable {
    let imageUrl: String
    let bookName: String
    let status: String
}
