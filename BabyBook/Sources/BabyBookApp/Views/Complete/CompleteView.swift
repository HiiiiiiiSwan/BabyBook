import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 完成页面（接入 PDF 生成和下载）
struct CompleteView: View {
    let book: Book
    let order: BackendOrder
    let task: BackendTask?

    @State private var isDownloading = false
    @State private var downloadSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    #if canImport(UIKit)
    @State private var downloadedImage: UIImage?
    #endif
    @State private var pdfGenerated = false
    @Environment(\.navPath) private var navPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    bookPreviewSection
                    actionButtons
                    weakWarning
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { goBackToHome() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#222222"))
                    }
                }
            }
        }
        #endif
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
                Text("专属绘本已生成！")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(.top, 20)
        }
    }

    private var bookPreviewSection: some View {
        VStack(spacing: 12) {
            // 正方形绘本封面
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)

                #if canImport(UIKit)
                if let image = downloadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    bookPreviewPlaceholder
                }
                #else
                bookPreviewPlaceholder
                #endif
            }
            .frame(width: 240, height: 240)

            Text("《\(book.name)》")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            Text("\(book.pageCount)页 · 中英双语")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
        .padding(.top, 16)
    }

    private var bookPreviewPlaceholder: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My First Book")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#666666"))
                    Text(book.name)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#999999"))
                }
                Spacer()
                Image(systemName: "face.smiling")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Image(systemName: "person.crop.square.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#F28C28").opacity(0.15))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Head", systemImage: "circle.fill")
                        .font(.system(size: 10))
                    Label("Hand", systemImage: "hand.fill")
                        .font(.system(size: 10))
                    Label("Foot", systemImage: "footprint.fill")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: "#999999"))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 下载绘本图片
            Button(action: { downloadBook() }) {
                HStack {
                    if isDownloading {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: downloadSuccess ? "checkmark.circle" : "arrow.down.doc")
                        Text(downloadSuccess ? "已保存到相册" : "保存绘本图片")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(downloadSuccess ? Color(hex: "#8BC34A") : Color(hex: "#F28C28"))
                .cornerRadius(24)
            }
            .disabled(isDownloading)

            // 生成 PDF
            Button(action: { generatePDF() }) {
                HStack {
                    Image(systemName: pdfGenerated ? "checkmark.circle" : "doc.fill")
                    Text(pdfGenerated ? "PDF 已生成" : "生成 PDF 电子版")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#666666"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                )
            }
            .disabled(isDownloading || pdfGenerated)

            Button(action: { openPhysicalBookStore() }) {
                Text("获取实体书（跳转微店）")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#666666"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                .background(Color.white)
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var weakWarning: some View {
        VStack(spacing: 4) {
            Text("请及时下载保存")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#999999"))
            Text("卸载App后将无法恢复哦~")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#CCCCCC"))
        }
        .padding(.top, 16)
    }

    // MARK: - 下载绘本图片
    private func downloadBook() {
        guard let task = task, let resultUrl = task.resultUrl else {
            errorMessage = "绘本图片链接不可用"
            showError = true
            return
        }

        isDownloading = true

        Task {
            do {
                // 下载图片数据
                let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)

                #if canImport(UIKit)
                if let image = UIImage(data: imageData) {
                    // 保存到相册
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                    // 保存到本地 Documents 目录
                    saveImageToDocuments(imageData: imageData)

                    await MainActor.run {
                        downloadedImage = image
                        isDownloading = false
                        downloadSuccess = true
                    }
                } else {
                    throw APIError.invalidResponse
                }
                #else
                // 非 UIKit 平台直接保存到 Documents
                saveImageToDocuments(imageData: imageData)
                await MainActor.run {
                    isDownloading = false
                    downloadSuccess = true
                }
                #endif
            } catch {
                await MainActor.run {
                    errorMessage = "下载失败: \(error.localizedDescription)"
                    showError = true
                    isDownloading = false
                }
            }
        }
    }

    // MARK: - 生成 PDF
    private func generatePDF() {
        #if canImport(UIKit)
        guard let image = downloadedImage else {
            errorMessage = "请先下载绘本图片"
            showError = true
            return
        }

        isDownloading = true

        Task {
            do {
                let pdfPath = try PDFService.shared.generatePDF(
                    from: image,
                    bookName: book.name,
                    orderId: order.id
                )

                await MainActor.run {
                    pdfGenerated = true
                    isDownloading = false
                    print("PDF 生成成功: \(pdfPath)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "PDF 生成失败: \(error.localizedDescription)"
                    showError = true
                    isDownloading = false
                }
            }
        }
        #else
        errorMessage = "PDF 生成仅在 iOS 平台可用"
        showError = true
        #endif
    }

    // MARK: - 打开实体书微店
    private func openPhysicalBookStore() {
        // TODO: 替换为实际微店链接
        let storeURL = URL(string: "https://weidian.com")!
        #if os(iOS)
        UIApplication.shared.open(storeURL)
        #endif
    }

    // 保存图片到 Documents 目录
    private func saveImageToDocuments(imageData: Data) {
        let fileName = "book_\(order.id).png"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentsPath.appendingPathComponent(fileName)
            try? imageData.write(to: filePath)
        }
    }

    // MARK: - 返回首页
    private func goBackToHome() {
        // 发送通知让根视图重置导航路径
        NotificationCenter.default.post(name: .resetNavigation, object: nil)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CompleteView(
            book: MockService.shared.mockBooks[0],
            order: BackendOrder(
                id: "test-order-id",
                deviceId: "test-device",
                bookId: "Book001",
                bookName: "《这是我》",
                amount: 12.99,
                status: "SUCCESS",
                createdAt: "2026-06-23T10:00:00Z",
                updatedAt: nil
            ),
            task: BackendTask(
                id: "test-task-id",
                orderId: "test-order-id",
                status: "COMPLETED",
                progress: 100,
                resultUrl: "https://example.com/generated.png",
                errorMessage: nil,
                createdAt: "2026-06-23T10:01:00Z",
                updatedAt: "2026-06-23T10:02:00Z"
            )
        )
    }
}
