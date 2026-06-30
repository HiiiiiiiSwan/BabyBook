import Foundation

// MARK: - Mock 数据服务
class MockService {
    static let shared = MockService()

    // MARK: - Mock 绘本数据
    let mockBooks: [Book] = [
        Book(
            id: "3",
            bookId: "Book003",
            name: "认识颜色",
            description: "颜色认知绘本，帮助宝宝认识红、橙、黄、绿、蓝、紫等基础颜色。通过可爱的插画和场景，让颜色学习变得有趣。",
            pageCount: 9,
            price: 1.0,
            coverImage: "color_recognition_cover",
            templatePath: "templates/color_recognition",
            type: .colorRecognition,
            pageImages: ["0_cover", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        ),
        Book(
            id: "2",
            bookId: "Book002",
            name: "我长大想做什么",
            description: "职业认知绘本，让宝宝了解各种有趣的职业。医生、消防员、宇航员、老师...激发宝宝对未来的想象。",
            pageCount: 9,
            price: 1.0,
            coverImage: "dream_job_cover",
            templatePath: "templates/dream_job",
            type: .careerRecognition,
            pageImages: ["0_cover", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        ),
        Book(
            id: "1",
            bookId: "Book001",
            name: "这是我",
            description: "宝宝身体认知绘本，帮助宝宝认识自己的身体部位。包含头部、眼睛、耳朵、鼻子、嘴巴、脖子、手、肚子、脚9个部位的可爱认知。",
            pageCount: 9,
            price: 1.0,
            coverImage: "self_intro_cover",
            templatePath: "templates/self_intro",
            type: .bodyRecognition,
            pageImages: ["0_cover", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        )
    ]

    // MARK: - 模拟订单创建
    func createOrder(bookId: String, deviceId: String) -> Order {
        let orderId = "ORD\(Int.random(in: 100000...999999))"
        return Order(
            id: UUID().uuidString,
            orderId: orderId,
            deviceId: deviceId,
            bookId: bookId,
            amount: 1.0,
            status: .unpaid,
            createTime: Date(),
            generateTime: nil,
            paymentId: nil
        )
    }

    // MARK: - 模拟支付验证
    func verifyPayment(orderId: String) -> Order {
        return Order(
            id: UUID().uuidString,
            orderId: orderId,
            deviceId: "mock_device",
            bookId: "Book001",
            amount: 1.0,
            status: .paid,
            createTime: Date(),
            generateTime: nil,
            paymentId: "mock_payment_\(Int.random(in: 1000...9999))"
        )
    }

    // MARK: - 模拟生成任务状态查询
    func queryTaskStatus(taskId: String) -> GenerationTask {
        let progress = Double.random(in: 0.0...1.0)
        let status: Order.OrderStatus = progress >= 1.0 ? .success : .generating

        return GenerationTask(
            id: taskId,
            orderId: taskId.replacingOccurrences(of: "TASK", with: "ORD"),
            status: status,
            progress: progress,
            imageUrl: status == .success ? "generated_image_url" : nil,
            pdfUrl: status == .success ? "generated_pdf_url" : nil,
            errorMessage: nil
        )
    }

    // MARK: - 模拟本地绘本列表
    func getLocalBooks() -> [LocalBook] {
        return []
    }
}
