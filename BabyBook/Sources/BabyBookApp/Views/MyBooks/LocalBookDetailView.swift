import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
import Photos
#endif

// MARK: - 绘本详情查看页（从我的绘本页点击进入）
struct LocalBookDetailView: View {
    let book: LocalBookMetadata
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showLeaveAppAlert = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSavingToPhotos = false
    @State private var isSavingPDF = false
    @State private var pdfGenerated = false
    @State private var downloadSuccess = false
    @State private var showSavePermissionAlert = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 可滚动内容区
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerSection
                            bookPreviewSection(width: geometry.size.width)
                            Spacer().frame(minHeight: 24)
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height - 220, alignment: .top)
                    }

                    // 底部固定操作区
                    actionButtons
                        .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("删除绘本", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#222222"))
                }
            }
        }
        #endif
        .alert("删除绘本", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("确定要删除这本绘本吗？删除后将无法恢复。")
        }
        .sheet(isPresented: $showShareSheet) {
            #if canImport(UIKit)
            ShareSheet(items: shareItems)
            #endif
        }
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("保存权限", isPresented: $showSavePermissionAlert) {
            Button("取消", role: .cancel) {}
            Button("前往设置") {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
        } message: {
            Text("需要访问相册权限才能保存绘本图片")
        }
        .alert("即将离开 App", isPresented: $showLeaveAppAlert) {
            Button("取消", role: .cancel) {}
            Button("继续") {
                openPhysicalBookStore()
            }
        } message: {
            Text("将打开 Safari 访问外部页面，是否继续？")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
                Text("宝宝的专属绘本")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(.top, 32)

            Text(formatDate(book.createTime))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
    }

    // MARK: - 绘本预览
    private func bookPreviewSection(width: CGFloat) -> some View {
        VStack(spacing: 20) {
            // 正方形绘本封面（屏幕宽度 - 64px 边距）
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)

                #if canImport(UIKit)
                if let uiImage = loadBookImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(12)
                } else {
                    bookPreviewPlaceholder
                }
                #else
                bookPreviewPlaceholder
                #endif
            }
            .frame(width: width - 64, height: width - 64)

            Text("《\(book.bookName)》")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))
        }
        .padding(.top, 32)
    }

    private var bookPreviewPlaceholder: some View {
        VStack(spacing: 8) {
            Spacer()
                .frame(height: 12)
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 0) {
            // 提示文案（主按钮上方 10pt，浅灰色一行）
            Text("请及时保存 卸载app后将无法恢复")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#CCCCCC"))
                .padding(.bottom, 10)

            VStack(spacing: 16) {
                // 保存绘本图片（主按钮）
                Button(action: { downloadBook() }) {
                    ZStack {
                        HStack(spacing: 6) {
                            Image(systemName: downloadSuccess ? "checkmark.circle" : "arrow.down.doc")
                            Text(downloadSuccess ? "已保存到相册" : "保存绘本图片")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(isSavingToPhotos ? 0 : 1)

                        if isSavingToPhotos {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(downloadSuccess ? Color(hex: "#8BC34A") : Color(hex: "#F28C28"))
                    .cornerRadius(28)
                }
                .disabled(isSavingToPhotos)

                // 保存逐页 PDF + 获取实体书（并排文字按钮，参考首页样式）
                HStack(spacing: 32) {
                    Button(action: { savePDF() }) {
                        HStack(spacing: 4) {
                            Text(pdfGenerated ? "PDF 已保存" : "导出PDF")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "#666666"))
                    }
                    .disabled(isSavingPDF)

                    Button(action: { showLeaveAppAlert = true }) {
                        HStack(spacing: 4) {
                            Text("获取实体书")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "#666666"))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color(hex: "#FFF9F2"))
    }

    // MARK: - 加载绘本图片
    #if canImport(UIKit)
    private func loadBookImage() -> UIImage? {
        return UIImage(contentsOfFile: book.filePath)
    }
    #endif

    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - 保存绘本图片
    private func downloadBook() {
        #if canImport(UIKit)
        isSavingToPhotos = true

        Task {
            guard let image = loadBookImage() else {
                await MainActor.run {
                    errorMessage = "绘本图片加载失败"
                    showError = true
                    isSavingToPhotos = false
                }
                return
            }

            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                await MainActor.run {
                    errorMessage = "图片数据转换失败"
                    showError = true
                    isSavingToPhotos = false
                }
                return
            }

            await saveImageToPhotos(image: image, imageData: imageData)
        }
        #else
        errorMessage = "保存绘本图片仅在 iOS 平台可用"
        showError = true
        #endif
    }

    // MARK: - 保存 PDF（生成本地 PDF 后拉起系统分享页）
    private func savePDF() {
        #if canImport(UIKit)
        isSavingPDF = true

        Task {
            guard let image = loadBookImage() else {
                await MainActor.run {
                    errorMessage = "绘本图片加载失败"
                    showError = true
                    isSavingPDF = false
                }
                return
            }

            do {
                let pdfPath = try PDFService.shared.generatePDF(
                    from: image,
                    bookName: book.bookName,
                    orderId: book.orderId
                )
                let pdfURL = URL(fileURLWithPath: pdfPath)

                await MainActor.run {
                    pdfGenerated = true
                    isSavingPDF = false
                    shareItems = [pdfURL]
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "PDF 保存失败: \(error.localizedDescription)"
                    showError = true
                    isSavingPDF = false
                }
            }
        }
        #else
        errorMessage = "PDF 保存仅在 iOS 平台可用"
        showError = true
        #endif
    }

    // MARK: - 保存图片到相册（带权限检查和结果回调）
    private func saveImageToPhotos(image: UIImage, imageData: Data) async {
        #if canImport(UIKit)
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: imageData, options: nil)
                }

                await MainActor.run {
                    isSavingToPhotos = false
                    downloadSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "保存到相册失败: \(error.localizedDescription)"
                    showError = true
                    isSavingToPhotos = false
                }
            }

        case .denied, .restricted:
            await MainActor.run {
                isSavingToPhotos = false
                showSavePermissionAlert = true
            }

        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                await saveImageToPhotos(image: image, imageData: imageData)
            } else {
                await MainActor.run {
                    isSavingToPhotos = false
                    showSavePermissionAlert = true
                }
            }

        @unknown default:
            await MainActor.run {
                isSavingToPhotos = false
                errorMessage = "无法访问相册"
                showError = true
            }
        }
        #endif
    }

    // MARK: - 删除绘本
    private func deleteBook() {
        // 删除图片文件
        if FileManager.default.fileExists(atPath: book.filePath) {
            try? FileManager.default.removeItem(atPath: book.filePath)
        }
        // 删除对应 PDF
        if let pdfPath = book.pdfFilePath, FileManager.default.fileExists(atPath: pdfPath) {
            try? FileManager.default.removeItem(atPath: pdfPath)
        } else {
            let legacyPDFPath = book.filePath.replacingOccurrences(of: ".png", with: ".pdf")
            if FileManager.default.fileExists(atPath: legacyPDFPath) {
                try? FileManager.default.removeItem(atPath: legacyPDFPath)
            }
        }
        // 删除元数据
        LocalBookStore.shared.delete(orderId: book.orderId)

        // 返回上一页
        dismiss()
    }

    // MARK: - 打开实体书微店
    private func openPhysicalBookStore() {
        let storeURL = URL(string: "https://weidian.com/?userid=1868613735")!

        #if os(iOS)
        UIApplication.shared.open(storeURL)
        #endif
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LocalBookDetailView(
            book: LocalBookMetadata(
                id: "test-order",
                orderId: "test-order",
                bookId: "Book001",
                bookName: "《这是我》",
                filePath: "/tmp/test.png",
                pdfFilePath: nil,
                createTime: Date()
            )
        )
    }
}
