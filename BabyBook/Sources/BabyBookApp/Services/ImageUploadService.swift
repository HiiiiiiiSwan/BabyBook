import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 图片上传服务（上传到后端临时存储）
class ImageUploadService {
    static let shared = ImageUploadService()

    private let session: URLSession
    private let uploadEndpoint: String

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        self.uploadEndpoint = APIConfig.fullBaseURL + "/upload/image"
    }

    #if canImport(UIKit)
    /// 上传宝宝照片到后端临时存储
    /// - Parameter image: 宝宝照片 UIImage
    /// - Returns: 图片 URL 字符串
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw UploadError.imageCompressionFailed
        }

        // 检查图片大小（限制 10MB）
        let maxSize = 10 * 1024 * 1024 // 10MB
        guard imageData.count <= maxSize else {
            throw UploadError.fileTooLarge
        }

        // 构建 multipart 请求
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: uploadEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 添加设备认证头
        request.setValue(DeviceService.shared.deviceId, forHTTPHeaderField: "X-Device-Id")

        // 构建请求体
        let body = createMultipartBody(imageData: imageData, boundary: boundary, filename: "baby_photo.jpg")
        request.httpBody = body

        // 发送请求
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "上传失败"
            throw UploadError.uploadFailed(errorMessage)
        }

        // 解析响应
        let decoder = JSONDecoder()
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)

        guard uploadResponse.success, let imageUrl = uploadResponse.imageUrl else {
            throw UploadError.invalidResponse
        }

        return imageUrl
    }

    /// 将图片转为 Base64（备用方案）
    func imageToBase64(_ image: UIImage, quality: CGFloat = 0.8) -> String? {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    #endif

    /// 构建 multipart 请求体
    private func createMultipartBody(imageData: Data, boundary: String, filename: String) -> Data {
        var body = Data()

        // 文件部分
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // 结束边界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
}

// MARK: - 上传响应模型
struct UploadResponse: Codable {
    let success: Bool
    let imageUrl: String?
    let filename: String?
    let size: Int?
}

// MARK: - 上传错误
enum UploadError: Error, LocalizedError {
    case imageCompressionFailed
    case fileTooLarge
    case uploadFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .fileTooLarge:
            return "图片过大，请上传不超过 10MB 的照片"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        case .invalidResponse:
            return "服务器响应异常"
        }
    }
}
