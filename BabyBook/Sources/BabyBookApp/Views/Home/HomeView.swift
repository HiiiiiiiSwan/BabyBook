import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 首页（截图布局版本）
struct HomeView: View {
    @State private var showGenerating = false
    @State private var showFailureResult = false
    @State private var restoredOrder: BackendOrder?
    @State private var restoredBook: Book?
    @State private var selectedBook: Book? = MockService.shared.mockBooks.first
    @State private var showDetail = false
    @State private var showUploadSheet = false
    @State private var showLeaveAppAlert = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            homeContent
        }
        .navigationDestination(isPresented: $showDetail) {
            if let book = selectedBook {
                BookDetailView(book: book)
            }
        }
        .navigationDestination(isPresented: $showGenerating) {
            if let book = restoredBook, let order = restoredOrder {
                GeneratingView(book: book, order: order, isRestored: true)
            }
        }
        .navigationDestination(isPresented: $showFailureResult) {
            if let book = restoredBook, let order = restoredOrder {
                FailureResultView(book: book, order: order, taskErrorMessage: nil)
            }
        }
        .overlay {
            if showUploadSheet {
                UploadPhotoSheet(book: selectedBook!, isPresented: $showUploadSheet)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetNavigation)) { _ in
            showUploadSheet = false
            showGenerating = false
            showFailureResult = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToGenerating)) { notification in
            if let userInfo = notification.object as? [String: Any],
               let book = userInfo["book"] as? Book,
               let order = userInfo["order"] as? BackendOrder {
                self.restoredBook = book
                self.restoredOrder = order
                self.showFailureResult = false
                self.showGenerating = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFailureResult)) { notification in
            if let userInfo = notification.object as? [String: Any],
               let book = userInfo["book"] as? Book,
               let order = userInfo["order"] as? BackendOrder {
                self.restoredBook = book
                self.restoredOrder = order
                self.showGenerating = false
                self.showFailureResult = true
            }
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

    // MARK: - 首页内容
    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                guideSection
                bookCarouselSection
                bottomActionSection
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            // 首页出现时触发一次健康检查，提前弹出网络和本地网络权限弹窗
            // 避免用户在上传照片流程中被打断
            triggerNetworkPermissionCheck()
        }
    }

    // MARK: - 自定义 TabBar（已移除）
    // 我的绘本入口已移至底部操作区，作为文字按钮展示

    // MARK: - 网络权限预触发
    /// 在首页出现时发起一次轻量网络请求，目的是让 iOS 尽早弹出
    /// 「无线数据」和「本地网络」权限弹窗，避免用户进入上传流程后才看到
    private func triggerNetworkPermissionCheck() {
        Task {
            do {
                let _: HealthResponse = try await NetworkService.shared.request(endpoint: .healthCheck)
            } catch {
                // 健康检查失败不需要提示用户，仅用于触发系统权限弹窗
                // 后续真实请求失败时会有对应错误提示
            }
        }
    }

    // MARK: - 顶部 App 名称
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image("appicon-small")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
            Text("宝贝绘本")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DesignTokens.Colors.primaryText)
            Text("BabyBook")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.Colors.tertiaryText)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Layout.pagePadding)
        .padding(.top, 24)
        .overlay(alignment: .topTrailing) {
            Image("balloon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.top, 80)
                .padding(.trailing, 20)
        }
    }

    // MARK: - 指引操作文案
    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("仅上传")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primaryText)
                Text("1张")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primary)
                Text("照片")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primaryText)
            }

            Text("即可让宝宝成为主角")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DesignTokens.Colors.primaryText)
            Text("获得专属绘本")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DesignTokens.Colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignTokens.Layout.pagePadding)
        .padding(.top, DesignTokens.Spacing.xl)
    }

    // MARK: - 绘本左右滑动选中
    private var bookCarouselSection: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedBook) {
                ForEach(MockService.shared.mockBooks) { book in
                    BookCarouselCard(book: book, onSelect: {
                        selectedBook = book
                        showDetail = true
                    })
                    .tag(book as Book?)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 360)

            // 页码指示器
            HStack(spacing: 8) {
                ForEach(MockService.shared.mockBooks) { book in
                    Circle()
                        .fill(selectedBook?.id == book.id ? DesignTokens.Colors.primary : DesignTokens.Colors.border)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 底部操作区
    private var bottomActionSection: some View {
        ZStack(alignment: .bottom) {
            // 底部插画（与一键定制按钮底部间距 55px，宽度与页面一致）
            Image("homeBG")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 65)

            // 按钮内容（置底展示）
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // 一键定制按钮（与绘本详情页样式一致）
                    ZStack(alignment: .bottom) {
                        Button(action: {
                            if selectedBook != nil {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showUploadSheet = true
                                }
                            }
                        }) {
                            Text("一键定制")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color(hex: "#F28C28"))
                                .cornerRadius(60)
                        }
                        .padding(.horizontal, 32)

                        Text("仅需¥\(String(format: "%.1f", selectedBook?.price ?? 3.0))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#E85D5D"))
                            .cornerRadius(12)
                            .offset(x: 80, y: -20)
                    }
                    .padding(.top, 16)

                    // 获取实体书 + 我的绘本（并排一行）
                    HStack(spacing: 32) {
                        Button(action: { showLeaveAppAlert = true }) {
                            HStack(spacing: 4) {
                                Text("获取实体书")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color(hex: "#666666"))
                        }

                        NavigationLink(destination: MyBooksView()) {
                            HStack(spacing: 4) {
                                Text("我的绘本")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color(hex: "#666666"))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }
}

    // MARK: - 绘本轮播卡片
struct BookCarouselCard: View {
    let book: Book
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            onSelect()
        }) {
            VStack(spacing: 16) {
                // 绘本封面展示
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.bookCover)
                        .fill(DesignTokens.Colors.pageBackground)
                        .frame(width: 280, height: 280)
                        .shadow(
                            color: DesignTokens.Shadows.card.color,
                            radius: DesignTokens.Shadows.card.radius,
                            x: DesignTokens.Shadows.card.x,
                            y: DesignTokens.Shadows.card.y
                        )

                    // 封面图片
                    if let coverImage = loadCoverImage() {
                        coverImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        // 封面占位图
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignTokens.Colors.secondary.opacity(0.3))
                                .frame(width: 240, height: 240)

                            Image(systemName: "person.crop.square.fill")
                                .font(.system(size: 60))
                                .foregroundColor(DesignTokens.Colors.primary.opacity(0.3))
                        }
                    }
                }

                // 绘本信息
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.background)

                    Text("《\(book.name)》")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    Image("arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.horizontal, DesignTokens.Layout.pagePadding)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 加载封面图片（优先从 Bundle 读取，回退到绝对路径）
    private func loadCoverImage() -> Image? {
        #if os(iOS)
        let bundlePath = "\(book.bundleFolder)/cover"
        if let uiImage = UIImage(named: bundlePath, in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }
        if let uiImage = UIImage(contentsOfFile: book.coverImage) {
            return Image(uiImage: uiImage)
        }
        #else
        if let nsImage = NSImage(contentsOfFile: book.coverImage) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}

// MARK: - 上传照片蒙层弹窗（首页/绘本详情共用）
struct UploadPhotoSheet: View {
    let book: Book
    @Binding var isPresented: Bool
    @State private var selectedPhoto: PhotosPickerItem? = nil
    #if canImport(UIKit)
    @State private var selectedImage: UIImage? = nil
    #endif
    @State private var isAnalyzing = false
    @State private var faceDetected = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToGenerating = false
    @State private var navigateToFailureResult = false
    @State private var isProcessingPayment = false
    @State private var isCreatingOrder = false
    @State private var isUploadingImage = false
    @State private var createdOrder: BackendOrder?
    @State private var uploadedImageUrl: String?
    @StateObject private var paymentService = PaymentService.shared
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showCamera = false
    @State private var showFaceDetectionError = false
    @State private var faceDetectionErrorMessage = ""
    @State private var showPhotoPicker = false

    var body: some View {
        ZStack {
            // 半透明黑色蒙层
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }

            // 底部弹窗内容
            VStack {
                Spacer()
                uploadSheetContent
                    .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationDestination(isPresented: $navigateToGenerating) {
            if let order = createdOrder {
                GeneratingView(book: book, order: order)
            }
        }
        .navigationDestination(isPresented: $navigateToFailureResult) {
            if let order = createdOrder {
                FailureResultView(book: book, order: BackendOrder(
                    id: order.id,
                    deviceId: order.deviceId,
                    bookId: order.bookId,
                    bookName: order.bookName,
                    amount: order.amount,
                    status: "FAILED",
                    createdAt: order.createdAt,
                    updatedAt: order.updatedAt
                ), taskErrorMessage: "支付成功但服务器连接异常，请添加客服微信协助处理")
            }
        }
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("相机权限", isPresented: $showPermissionAlert) {
            Button("取消", role: .cancel) {}
            Button("前往设置") {
                #if canImport(UIKit)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
        } message: {
            Text(permissionAlertMessage)
        }
        .alert("人脸检测", isPresented: $showFaceDetectionError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(faceDetectionErrorMessage)
        }
        .overlay {
            if isUploadingImage || isCreatingOrder || isProcessingPayment {
                LoadingOverlay(message: overlayMessage)
            }
        }
        .sheet(isPresented: $showCamera) {
            #if canImport(UIKit)
            CameraView(
                capturedImage: $selectedImage,
                isPresented: $showCamera,
                onCapture: { _ in
                    performFaceDetection()
                },
                onCancel: {}
            )
            #endif
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhoto,
            matching: .images
        )
    }

    private var uploadSheetContent: some View {
        VStack(spacing: 0) {
            // 拖拽指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignTokens.Colors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 16)

            // 关闭按钮 + 标题
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("请上传照片并完成支付")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    Text("定制专属《\(book.name)》，仅需\(Text("1张").foregroundColor(DesignTokens.Colors.primary))宝宝照片并支付\(Text("￥\(String(format: "%.1f", book.price))").foregroundColor(DesignTokens.Colors.primary))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.secondaryText)
                }
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(DesignTokens.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, DesignTokens.Layout.pagePadding)
            .padding(.top, 24)

            // 建议照片 + 示例
            HStack(spacing: 24) {
                // 建议照片
                VStack(alignment: .leading, spacing: 12) {
                    Text("上传照片建议：")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    VStack(alignment: .leading, spacing: 10) {
                        CheckItem(text: "正脸清晰")
                        CheckItem(text: "光线充足")
                        CheckItem(text: "背景干净")
                    }
                }
                .padding(.leading, 24)

                Spacer()

                // 示例照片
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DesignTokens.Colors.secondary.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image("photocase")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("示例")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.primary)
                        .clipShape(PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .bottomRight]))
                }
                .padding(.trailing, 24)
            }
            .padding(.vertical, 20)
            .background(Color(hex: "#F5F5F5"))
            .cornerRadius(16)
            .padding(.top, 16)
            .padding(.horizontal, 24)

            // 按钮：拍照（次按钮）+ 从相册选择（主按钮）
            HStack(spacing: 12) {
                // 拍照按钮（次按钮样式：浅色底主色字）
                Button(action: { checkCameraPermission() }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignTokens.Colors.secondary.opacity(0.3))
                    .cornerRadius(28)
                }

                // 从相册选择按钮（主按钮样式：黄色底白字）
                #if targetEnvironment(simulator)
                Button(action: {
                    #if canImport(UIKit)
                    if let image = UIImage(named: "babyimage", in: Bundle.main, compatibleWith: nil) {
                        selectedImage = image
                    } else {
                        selectedImage = createPlaceholderImage()
                    }
                    performFaceDetection()
                    #endif
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(28)
                }
                #else
                Button(action: {
                    showPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(28)
                }
                #endif
            }
            .padding(.horizontal, DesignTokens.Layout.pagePadding)
            .padding(.top, 40)
            .padding(.bottom, 32)
        }
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: -4
        )
        .onChange(of: selectedPhoto) { newItem in
            guard let newItem else { return }
            selectedPhoto = nil
            loadImage(from: newItem)
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        isAnalyzing = true; faceDetected = false
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data?):
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    } else {
                        selectedImage = nil
                    }
                    #endif
                    performFaceDetection()
                case .success(nil):
                    errorMessage = "无法读取图片"; showError = true; isAnalyzing = false
                case .failure(let error):
                    errorMessage = "加载失败: \(error.localizedDescription)"; showError = true; isAnalyzing = false
                }
            }
        }
    }

    private func checkCameraPermission() {
        #if canImport(UIKit)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .denied, .restricted:
            permissionAlertMessage = "需要访问相机才能拍摄宝宝照片，请在设置中开启权限"
            showPermissionAlert = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        permissionAlertMessage = "需要访问相机才能拍摄宝宝照片，请在设置中开启权限"
                        showPermissionAlert = true
                    }
                }
            }
        @unknown default:
            break
        }
        #endif
    }

    private func performFaceDetection() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isAnalyzing = true
        faceDetected = false

        Task {
            let result = await FaceDetectionService.shared.detectFaces(in: image)
            await MainActor.run {
                isAnalyzing = false
                switch result {
                case .success:
                    faceDetected = true
                    uploadImageAndCreateOrder()
                case .noFaceDetected:
                    faceDetectionErrorMessage = "未检测到人脸，请上传宝宝正脸清晰照片"
                    showFaceDetectionError = true
                case .multipleFacesDetected(let count):
                    faceDetectionErrorMessage = "检测到 \(count) 张人脸，请只上传1张宝宝照片"
                    showFaceDetectionError = true
                case .failed(let error):
                    faceDetectionErrorMessage = "人脸检测失败: \(error.localizedDescription)"
                    showFaceDetectionError = true
                }
            }
        }
        #else
        // 非 UIKit 平台跳过人脸检测
        faceDetected = true
        uploadImageAndCreateOrder()
        #endif
    }

    private var overlayMessage: String {
        if isUploadingImage {
            return "正在上传照片..."
        } else if isCreatingOrder {
            return "正在创建订单..."
        } else if isProcessingPayment {
            return "正在唤起支付..."
        }
        return ""
    }

    private func uploadImageAndCreateOrder() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isUploadingImage = true

        Task {
            do {
                #if targetEnvironment(simulator)
                // 模拟器环境：跳过真实上传，使用 mock 图片 URL
                try await Task.sleep(nanoseconds: 800_000_000)
                let mockImageUrl = "https://mock.babybook.app/images/baby_\(Int.random(in: 1000...9999)).jpg"
                uploadedImageUrl = mockImageUrl
                await MainActor.run {
                    isUploadingImage = false
                }
                createOrder(imageUrl: mockImageUrl)
                #else
                let imageUrl = try await ImageUploadService.shared.uploadImage(image)
                uploadedImageUrl = imageUrl

                await MainActor.run {
                    isUploadingImage = false
                }

                createOrder(imageUrl: imageUrl)
                #endif
            } catch {
                await MainActor.run {
                    errorMessage = "图片上传失败: \(error.localizedDescription)"
                    showError = true
                    isUploadingImage = false
                }
            }
        }
        #else
        createOrder(imageUrl: nil)
        #endif
    }

    private func createOrder(imageUrl: String? = nil) {
        #if canImport(UIKit)
        guard selectedImage != nil else { return }
        #endif
        isCreatingOrder = true

        Task {
            do {
                #if targetEnvironment(simulator)
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let mockOrder = BackendOrder(
                    id: "mock-order-\(Int.random(in: 1000...9999))",
                    deviceId: "simulator-device",
                    bookId: book.bookId,
                    bookName: book.name,
                    amount: book.price,
                    status: "UNPAID",
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    updatedAt: nil
                )
                await MainActor.run {
                    createdOrder = mockOrder
                    isCreatingOrder = false
                }
                // 保存订单到本地（用于崩溃恢复）
                OrderStatusManager.shared.saveCurrentOrder(mockOrder)
                await startPayment(order: mockOrder)
                #else
                let deviceId = DeviceService.shared.deviceId
                let order = try await NetworkService.shared.createOrder(
                    bookId: book.bookId,
                    deviceId: deviceId,
                    imageUrl: imageUrl
                )

                await MainActor.run {
                    createdOrder = order
                    isCreatingOrder = false
                }
                // 保存订单到本地（用于崩溃恢复）
                OrderStatusManager.shared.saveCurrentOrder(order)
                await startPayment(order: order)
                #endif
            } catch {
                await MainActor.run {
                    errorMessage = "创建订单失败: \(error.localizedDescription)"
                    showError = true
                    isCreatingOrder = false
                }
            }
        }
    }

    private func startPayment(order: BackendOrder) async {
        isProcessingPayment = true
        do {
            #if targetEnvironment(simulator)
            try await Task.sleep(nanoseconds: 1_500_000_000)
            #else
            // 确保 IAP 产品已加载（从弹窗直接支付时可能尚未加载）
            if paymentService.products.isEmpty {
                await paymentService.loadProducts()
            }
            guard paymentService.product(for: book.bookId) != nil else {
                throw PaymentError.productNotFound
            }
            let _ = try await paymentService.purchase(
                bookId: book.bookId,
                orderId: order.id
            )
            if let imageUrl = uploadedImageUrl {
                try? await NetworkService.shared.updateOrderImage(
                    orderId: order.id,
                    imageUrl: imageUrl
                )
            }
            #endif
            await MainActor.run {
                isProcessingPayment = false

                // 支付成功后立即把本地订单更新为 PAID，
                // 这样即使立刻杀端，恢复时也能识别为已支付的绘本订单。
                if let paidOrder = createdOrder?.updatingStatus(to: "PAID") {
                    OrderStatusManager.shared.currentOrder = paidOrder
                    OrderStatusManager.shared.saveCurrentOrder(paidOrder)
                }

                withAnimation(.easeInOut(duration: 0.25)) {
                    isPresented = false
                }
                navigateToGenerating = true
            }
        } catch PaymentError.userCancelled {
            await MainActor.run {
                isProcessingPayment = false
            }
        } catch {
            await MainActor.run {
                isProcessingPayment = false
                if let paymentError = error as? PaymentError,
                   case .paidButServerError = paymentError {
                    // Apple 已扣款，但后端验证/任务创建失败，进入失败结果页联系客服
                    navigateToFailureResult = true
                } else {
                    // Apple 支付阶段失败（未付款成功）
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#if canImport(UIKit)
private func createPlaceholderImage() -> UIImage {
    let size = CGSize(width: 200, height: 200)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }

    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor(red: 0.95, green: 0.55, blue: 0.16, alpha: 1.0).cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    let icon = UIImage(systemName: "face.smiling.fill")!
    let iconSize = CGSize(width: 80, height: 80)
    let iconRect = CGRect(
        x: (size.width - iconSize.width) / 2,
        y: (size.height - iconSize.height) / 2,
        width: iconSize.width,
        height: iconSize.height
    )
    icon.draw(in: iconRect)

    return UIGraphicsGetImageFromCurrentImageContext()!
}
#endif

// MARK: - 打开实体书微店
private func openPhysicalBookStore() {
    let storeURL = URL(string: "https://weidian.com/?userid=1868613735")!

    #if os(iOS)
    UIApplication.shared.open(storeURL)
    #endif
}

// MARK: - 部分圆角形状（用于示例标签）
struct PartialRoundedRectangle: Shape {
    let cornerRadius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}