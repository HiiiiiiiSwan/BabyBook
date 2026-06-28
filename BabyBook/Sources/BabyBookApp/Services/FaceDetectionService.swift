import Foundation
#if canImport(UIKit)
import UIKit
import Vision

// MARK: - 人脸检测服务
/// 基于 Apple Vision 框架的人脸检测服务
/// 用于验证用户上传的照片是否包含人脸，确保 AI 生成绘本时有清晰的人物主体
class FaceDetectionService {
    static let shared = FaceDetectionService()

    /// 人脸检测结果
    enum DetectionResult {
        case success(faceCount: Int)
        case noFaceDetected
        case multipleFacesDetected(count: Int)
        case failed(Error)
    }

    /// 检测图片中的人脸
    /// - Parameters:
    ///   - image: 待检测的 UIImage
    ///   - completion: 检测结果回调（主线程）
    func detectFaces(in image: UIImage, completion: @escaping (DetectionResult) -> Void) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                completion(.failed(FaceDetectionError.invalidImage))
            }
            return
        }

        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failed(error))
                }
                return
            }

            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                DispatchQueue.main.async {
                    completion(.noFaceDetected)
                }
                return
            }

            let faceCount = results.count
            if faceCount > 1 {
                DispatchQueue.main.async {
                    completion(.multipleFacesDetected(count: faceCount))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(faceCount: faceCount))
                }
            }
        }

        // 配置请求：检测人脸角度（提高检测率）
        if #available(iOS 15.0, *) {
            request.revision = VNDetectFaceRectanglesRequestRevision3
        }

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: .init(image.imageOrientation),
            options: [:]
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failed(error))
                }
            }
        }
    }

    /// 异步检测人脸（Swift Concurrency 版本）
    func detectFaces(in image: UIImage) async -> DetectionResult {
        await withCheckedContinuation { continuation in
            detectFaces(in: image) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: - 错误类型
enum FaceDetectionError: LocalizedError {
    case invalidImage
    case visionFrameworkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取图片数据"
        case .visionFrameworkUnavailable:
            return "人脸检测功能暂不可用"
        }
    }
}

// MARK: - UIImageOrientation 转 VNImageOrientation
@available(iOS 11.0, *)
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
