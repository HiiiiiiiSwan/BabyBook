import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
import Photos
#endif

// MARK: - 完成页面（接入 PDF 生成和下载）
struct CompleteView: View {
    let book: Book
    let order: BackendOrder
    let task: BackendTask?
    let preloadedImage: UIImage?

    @State private var isLoadingImage = false
    @State private var isSavingToPhotos = false
    @State private var isSavingPDF = false
    @State private var downloadSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    #if canImport(UIKit)
    @State private var downloadedImage: UIImage?
    #endif
    @State private var pdfGenerated = false
    @State private var showSavePermissionAlert = false
    @State private var saveSuccessMessage = ""
    @State private var showLeaveAppAlert = false
    @Environment(\.navPath) private var navPath
    @Environment(\.dismiss) private var dismiss

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
                Button(action: { goBackToHome() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))
                }
            }
        }
        #endif
        .onAppear {
            // 兜底：如果本地没有保存记录，尝试重新下载保存
            ensureBookSavedLocally()
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
        .sheet(isPresented: $showShareSheet) {
            #if canImport(UIKit)
            ShareSheet(items: shareItems)
            #endif
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

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
                Text("专属绘本已生成")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(.top, 32)
        }
    }

    private func bookPreviewSection(width: CGFloat) -> some View {
        VStack(spacing: 20) {
            // 正方形绘本封面（屏幕宽度 - 64px 边距）
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)

                #if canImport(UIKit)
                if let image = downloadedImage {
                    Image(uiImage: image)
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

            Text("《\(book.name)》")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))
        }
        .padding(.top, 32)
        .task {
            await autoLoadBookImage()
        }
    }

    private var bookPreviewPlaceholder: some View {
        VStack(spacing: 8) {
            Spacer()
                .frame(height: 12)
        }
    }

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
                .disabled(isSavingToPhotos || isLoadingImage)

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
                    .disabled(isSavingPDF || isLoadingImage)

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

    // MARK: - 兜底：确保绘本已保存到本地（我的绘本列表需要）
    private func ensureBookSavedLocally() {
        #if canImport(UIKit)
        // 已经有本地记录则跳过
        if let localBook = LocalBookStore.shared.get(orderId: order.id),
           FileManager.default.fileExists(atPath: localBook.filePath) {
            return
        }

        guard let resultUrl = task?.resultUrl else { return }

        Task {
            do {
                print("[CompleteView 兜底] 本地无记录，开始下载保存，URL: \(resultUrl)")
                let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)
                guard UIImage(data: imageData) != nil else {
                    print("[CompleteView 兜底] 下载数据无法解析为图片")
                    return
                }

                guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("[CompleteView 兜底] 无法获取 Documents 目录")
                    return
                }

                let fileName = "book_\(order.id).png"
                let filePath = documentsPath.appendingPathComponent(fileName)
                try imageData.write(to: filePath)

                LocalBookStore.shared.save(
                    orderId: order.id,
                    bookId: book.bookId,
                    bookName: book.name,
                    filePath: filePath.path,
                    createTime: parseISODateForComplete(task?.updatedAt) ?? Date()
                )
                print("[CompleteView 兜底] 本地保存成功: \(filePath.path)")
            } catch {
                print("[CompleteView 兜底] 保存失败: \(error)")
            }
        }
        #endif
    }

    private func parseISODateForComplete(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    // MARK: - 加载绘本图片（自动加载/保存/PDF 共用缓存）
    #if canImport(UIKit)
    private func loadBookImage() async throws -> UIImage {
        // 已缓存则直接返回
        if let image = downloadedImage {
            return image
        }

        // 优先使用预加载图片
        if let preloadedImage = preloadedImage {
            await MainActor.run {
                downloadedImage = preloadedImage
            }
            return preloadedImage
        }

        // 优先使用本地已保存的绘本图片
        if let localBook = LocalBookStore.shared.get(orderId: order.id),
           FileManager.default.fileExists(atPath: localBook.filePath),
           let localImage = UIImage(contentsOfFile: localBook.filePath) {
            await MainActor.run {
                downloadedImage = localImage
            }
            return localImage
        }

        guard let task = task, let resultUrl = task.resultUrl else {
            throw APIError.invalidResponse
        }

        await MainActor.run {
            isLoadingImage = true
        }

        defer {
            Task { @MainActor in
                isLoadingImage = false
            }
        }

        let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)

        guard let image = UIImage(data: imageData) else {
            throw APIError.invalidResponse
        }
        await MainActor.run {
            downloadedImage = image
        }
        return image
    }

    // MARK: - 页面进入时自动加载绘本图片（仅用于预览，不触发保存/PDF）
    private func autoLoadBookImage() async {
        guard downloadedImage == nil else { return }

        do {
            _ = try await loadBookImage()
        } catch {
            print("自动加载绘本图片失败: \(error)")
        }
    }
    #endif

    // MARK: - 保存绘本图片
    private func downloadBook() {
        #if canImport(UIKit)
        isSavingToPhotos = true

        Task {
            do {
                let image = try await loadBookImage()
                guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                    throw APIError.invalidResponse
                }
                await saveImageToPhotos(image: image, imageData: imageData)
            } catch {
                await MainActor.run {
                    errorMessage = "保存失败: \(error.localizedDescription)"
                    showError = true
                    isSavingToPhotos = false
                }
            }
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
            do {
                let image = try await loadBookImage()
                let pdfPath = try PDFService.shared.generatePDF(
                    from: image,
                    bookName: book.name,
                    orderId: order.id
                )
                let pdfURL = URL(fileURLWithPath: pdfPath)

                // 更新本地绘本元数据，记录 PDF 路径
                LocalBookStore.shared.save(
                    orderId: order.id,
                    bookId: order.bookId,
                    bookName: book.name,
                    filePath: pdfPath.replacingOccurrences(of: ".pdf", with: ".png"),
                    pdfFilePath: pdfPath,
                    createTime: parseISODate(task?.updatedAt) ?? Date()
                )

                await MainActor.run {
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

    // MARK: - 打开实体书微店
    private func openPhysicalBookStore() {
        let storeURL = URL(string: "https://weidian.com/?userid=1868613735")!

        #if os(iOS)
        UIApplication.shared.open(storeURL)
        #endif
    }

    // MARK: - 保存图片到相册（带权限检查和结果回调）
    private func saveImageToPhotos(image: UIImage, imageData: Data) async {
        #if canImport(UIKit)
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            // 有权限，保存到相册
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: imageData, options: nil)
                }

                await MainActor.run {
                    downloadedImage = image
                    isSavingToPhotos = false
                    downloadSuccess = true
                    saveSuccessMessage = "绘本已保存到相册"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "保存到相册失败: \(error.localizedDescription)"
                    showError = true
                    isSavingToPhotos = false
                }
            }

        case .denied, .restricted:
            // 权限被拒绝
            await MainActor.run {
                isSavingToPhotos = false
                showSavePermissionAlert = true
            }

        case .notDetermined:
            // 请求权限
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                // 权限 granted，递归调用保存
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

    // 保存图片到 Documents 目录
    private func saveImageToDocuments(imageData: Data) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileName = "book_\(order.id).png"
        let filePath = documentsPath.appendingPathComponent(fileName)
        do {
            try imageData.write(to: filePath)
        } catch {
            print("保存到 Documents 失败: \(error)")
        }

        // 同时保存绘本元数据
        LocalBookStore.shared.save(
            orderId: order.id,
            bookId: order.bookId,
            bookName: book.name,
            filePath: filePath.path,
            pdfFilePath: nil,
            createTime: parseISODate(task?.updatedAt) ?? Date()
        )
    }

    private func parseISODate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    // MARK: - 返回首页（通过 UIKit 导航控制器直接 pop 到根页面）
    private func goBackToHome() {
        #if os(iOS)
        popToRootViewController()
        #endif
    }
}

#if os(iOS)
// MARK: - UIKit 导航辅助：找到当前窗口的 NavigationController 并 pop 到根页面
private func popToRootViewController() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        return
    }

    if let navController = findNavigationController(from: rootViewController) {
        navController.popToRootViewController(animated: true)
    }
}

private func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
    if let navController = viewController as? UINavigationController {
        return navController
    }

    for child in viewController.children {
        if let navController = findNavigationController(from: child) {
            return navController
        }
    }

    if let presented = viewController.presentedViewController {
        return findNavigationController(from: presented)
    }

    return nil
}
#endif

// MARK: - Preview
#Preview("默认状态") {
    NavigationStack {
        CompleteView(
            book: MockService.shared.mockBooks[0],
            order: BackendOrder(
                id: "test-order-id",
                deviceId: "test-device",
                bookId: "Book001",
                bookName: "《这是我》",
                amount: 3.0,
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
            ),
            preloadedImage: nil
        )
    }
}

// MARK: - 截图用 Preview：下载成功状态
struct CompleteViewDownloadSuccess: View {
    var body: some View {
        NavigationStack {
            CompleteView(
                book: MockService.shared.mockBooks[0],
                order: BackendOrder(
                    id: "test-order-id",
                    deviceId: "test-device",
                    bookId: "Book001",
                    bookName: "《这是我》",
                    amount: 3.0,
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
                ),
                preloadedImage: nil
            )
            .onAppear {
                // 模拟下载成功状态
            }
        }
    }
}

#Preview("下载成功") {
    CompleteViewDownloadSuccess()
}
