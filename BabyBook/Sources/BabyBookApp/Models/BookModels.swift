import Foundation

// MARK: - 绘本模型
struct Book: Identifiable, Codable, Hashable {
    let id: String
    let bookId: String
    let name: String
    let description: String
    let pageCount: Int
    let price: Double
    let coverImage: String
    let templatePath: String
    let type: BookType
    let pageImages: [String]  // 绘本内容页图片文件名数组

    /// Bundle 中资源文件夹名称（与 Resources 下目录名一致）
    var bundleFolder: String {
        switch bookId {
        case "Book001":
            return "self_intro"
        case "Book002":
            return "dream_job"
        case "Book003":
            return "color_recognition"
        default:
            return templatePath
        }
    }

    enum BookType: String, Codable {
        case bodyRecognition = "body_recognition"      // 身体认知
        case careerRecognition = "career_recognition"  // 职业认知
        case colorRecognition = "color_recognition"    // 颜色认知
    }
}

// MARK: - 订单模型
struct Order: Identifiable, Codable {
    let id: String
    let orderId: String
    let deviceId: String
    let bookId: String
    let amount: Double
    var status: OrderStatus
    let createTime: Date
    var generateTime: Date?
    var paymentId: String?

    enum OrderStatus: String, Codable {
        case unpaid = "UNPAID"
        case paid = "PAID"
        case generating = "GENERATING"
        case success = "SUCCESS"
        case failed = "FAILED"
        case refund = "REFUND"
    }
}

// MARK: - 生成任务模型
struct GenerationTask: Identifiable, Codable {
    let id: String
    let orderId: String
    var status: Order.OrderStatus
    var progress: Double  // 0.0 ~ 1.0
    var imageUrl: String?
    var pdfUrl: String?
    var errorMessage: String?
}

// MARK: - 本地绘本（已下载PDF）
struct LocalBook: Identifiable {
    let id: String
    let orderId: String
    let bookName: String
    let filePath: String
    let createTime: Date
    let fileSize: Int64
}
