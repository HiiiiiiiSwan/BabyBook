import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import PDFKit

// MARK: - PDF 生成服务
class PDFService {
    static let shared = PDFService()

    #if canImport(UIKit)
    /// 将九宫格图片分割为单页并生成 PDF
    /// - Parameters:
    ///   - image: 2048x2048 的九宫格图片
    ///   - bookName: 绘本名称
    ///   - orderId: 订单ID
    /// - Returns: 生成的 PDF 文件路径
    func generatePDF(from image: UIImage, bookName: String, orderId: String) throws -> String {
        let pageSize = CGSize(width: 612, height: 612) // 8.5x8.5 英寸（正方形绘本）
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        // 九宫格布局：3x3
        let gridSize = 3
        let cellWidth = image.size.width / CGFloat(gridSize)
        let cellHeight = image.size.height / CGFloat(gridSize)

        let data = renderer.pdfData { context in
            // 封面页
            context.beginPage()
            drawCoverPage(context: context, bookName: bookName, pageSize: pageSize)

            // 九宫格内容页（9页）
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let pageIndex = row * gridSize + col

                    // 计算裁剪区域
                    let cropRect = CGRect(
                        x: CGFloat(col) * cellWidth,
                        y: CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )

                    // 裁剪图片
                    if let croppedImage = cropImage(image, to: cropRect) {
                        context.beginPage()
                        drawContentPage(context: context, image: croppedImage, pageIndex: pageIndex, pageSize: pageSize)
                    }
                }
            }

            // 封底页
            context.beginPage()
            drawBackCoverPage(context: context, pageSize: pageSize)
        }

        // 保存到 Documents 目录
        let fileName = "book_\(orderId).pdf"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PDFError.saveFailed
        }

        let filePath = documentsPath.appendingPathComponent(fileName)
        try data.write(to: filePath)

        return filePath.path
    }

    /// 裁剪图片
    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // 转换坐标系（UIKit 原点在左上角，CGImage 也在左上角，但 Y 轴方向需要注意）
        let scaledRect = CGRect(
            x: rect.origin.x * image.scale,
            y: rect.origin.y * image.scale,
            width: rect.width * image.scale,
            height: rect.height * image.scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 绘制封面页
    private func drawCoverPage(context: UIGraphicsPDFRendererContext, bookName: String, pageSize: CGSize) {
        let ctx = context.cgContext

        // 背景色
        ctx.setFillColor(UIColor(hex: "#FFF9F2").cgColor)
        ctx.fill(CGRect(origin: .zero, size: pageSize))

        // 标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor(hex: "#222222")
        ]
        let titleString = NSAttributedString(string: bookName, attributes: titleAttributes)
        let titleSize = titleString.size()
        titleString.draw(at: CGPoint(x: (pageSize.width - titleSize.width) / 2, y: 100))

        // 副标题
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor(hex: "#666666")
        ]
        let subtitleString = NSAttributedString(string: "专属定制绘本", attributes: subtitleAttributes)
        let subtitleSize = subtitleString.size()
        subtitleString.draw(at: CGPoint(x: (pageSize.width - subtitleSize.width) / 2, y: 150))

        // 装饰元素
        ctx.setFillColor(UIColor(hex: "#F28C28").cgColor)
        ctx.addEllipse(in: CGRect(x: pageSize.width - 80, y: pageSize.height - 80, width: 60, height: 60))
        ctx.fillPath()
    }

    /// 绘制内容页
    private func drawContentPage(context: UIGraphicsPDFRendererContext, image: UIImage, pageIndex: Int, pageSize: CGSize) {
        let ctx = context.cgContext

        // 背景色
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(origin: .zero, size: pageSize))

        // 计算图片绘制区域（居中，留边距）
        let margin: CGFloat = 40
        let drawRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )

        // 绘制图片
        image.draw(in: drawRect)

        // 页码
        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(hex: "#999999")
        ]
        let pageNumberString = NSAttributedString(string: "\(pageIndex + 1)", attributes: pageNumberAttributes)
        let pageNumberSize = pageNumberString.size()
        pageNumberString.draw(at: CGPoint(x: (pageSize.width - pageNumberSize.width) / 2, y: pageSize.height - 30))
    }

    /// 绘制封底页
    private func drawBackCoverPage(context: UIGraphicsPDFRendererContext, pageSize: CGSize) {
        let ctx = context.cgContext

        // 背景色
        ctx.setFillColor(UIColor(hex: "#FFF9F2").cgColor)
        ctx.fill(CGRect(origin: .zero, size: pageSize))

        // 感谢文字
        let thanksAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(hex: "#222222")
        ]
        let thanksString = NSAttributedString(string: "谢谢阅读！", attributes: thanksAttributes)
        let thanksSize = thanksString.size()
        thanksString.draw(at: CGPoint(x: (pageSize.width - thanksSize.width) / 2, y: pageSize.height / 2 - 20))

        // App 标识
        let appAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(hex: "#999999")
        ]
        let appString = NSAttributedString(string: "BabyBook · 宝贝绘本", attributes: appAttributes)
        let appSize = appString.size()
        appString.draw(at: CGPoint(x: (pageSize.width - appSize.width) / 2, y: pageSize.height - 80))
    }
    #endif
}

// MARK: - PDF 错误
enum PDFError: Error, LocalizedError {
    case saveFailed
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "PDF 保存失败"
        case .imageProcessingFailed:
            return "图片处理失败"
        }
    }
}

// MARK: - UIColor 扩展（支持 Hex）
#if canImport(UIKit)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
#endif
