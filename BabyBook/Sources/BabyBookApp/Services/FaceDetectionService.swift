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
    ///   - completion: 检测结果回调（主线程），保证只调用一次
    func detectFaces(in image: UIImage, completion: @escaping (DetectionResult) -> Void) {
        // 模拟器环境：iOS 26+ 模拟器经常出现 Vision 推理上下文创建失败，
        // 为避免调试/截图时崩溃，直接返回成功（单张人脸）
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            completion(.success(faceCount: 1))
        }
        return
        #endif

        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                completion(.failed(FaceDetectionError.invalidImage))
            }
            return
        }

        // 使用 NSLock 保证 completion 只调用一次，防止 Vision 在 perform 失败
        // 和 request 回调中重复触发导致 continuation 崩溃
        let completedLock = NSLock()
        var hasCompleted = false
        let safeComplete: (DetectionResult) -> Void = { result in
            completedLock.lock()
            defer { completedLock.unlock() }
            guard !hasCompleted else { return }
            hasCompleted = true
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                safeComplete(.failed(error))
                return
            }

            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                safeComplete(.noFaceDetected)
                return
            }

            let faceCount = results.count
            if faceCount > 1 {
                safeComplete(.multipleFacesDetected(count: faceCount))
            } else {
                safeComplete(.success(faceCount: faceCount))
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
                safeComplete(.failed(error))
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
