import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 首页（截图布局版本）
struct HomeView: View {
    @State private var selectedBook: Book? = nil
    @State private var showDetail = false
    @State private var showUploadSheet = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    guideSection
                    bookCarouselSection
                    bottomActionSection
                    // 调试入口
                    debugSection
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            if let book = selectedBook {
                BookDetailView(book: book)
            }
        }
        .overlay {
            if showUploadSheet {
                UploadPhotoSheet(book: selectedBook!, isPresented: $showUploadSheet)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }

    // MARK: - 顶部 App 名称
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 20))
                .foregroundColor(DesignTokens.Colors.primary)
            Text("宝贝绘本")
                .font(DesignTokens.Typography.h2)
                .foregroundColor(DesignTokens.Colors.primaryText)
            Text("BabyBook")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.tertiaryText)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Layout.pagePadding)
        .padding(.top, DesignTokens.Spacing.xl)
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
        .padding(.horizontal, DesignTokens.Layout.pagePadding)
        .padding(.top, DesignTokens.Spacing.xl)
    }

    // MARK: - 绘本左右滑动选中
    private var bookCarouselSection: some View {
        VStack(spacing: 16) {
            TabView(selection: $selectedBook) {
                ForEach(MockService.shared.mockBooks) { book in
                    BookCarouselCard(book: book)
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
        .padding(.top, DesignTokens.Spacing.xl)
    }

    // MARK: - 底部操作区
    private var bottomActionSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
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

                    Text("仅需¥\(String(format: "%.1f", selectedBook?.price ?? 9.9))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E85D5D"))
                        .cornerRadius(12)
                        .offset(x: 80, y: -20)
                }
                .padding(.top, 16)

                // 获取实体书按钮 + 我的绘本按钮
                HStack(spacing: 40) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Text("获取实体书")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "#666666"))
                    }

                    Button(action: {}) {
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
            .background(Color(hex: "#FFF9F2"))
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }

    // MARK: - 调试入口
    private var debugSection: some View {
        VStack(spacing: 12) {
            Text("调试入口")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DesignTokens.Colors.tertiaryText)

            NavigationLink(destination: UploadPhotoView(book: MockService.shared.mockBooks[0])) {
                Text("查看上传照片页")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(22)
            }

            NavigationLink(destination: PaymentView(book: MockService.shared.mockBooks[0], order: BackendOrder(id: "test-order", deviceId: "test", bookId: "Book001", bookName: "《这是我》", amount: 9.9, status: "UNPAID", createdAt: "2026-06-24T10:00:00Z", updatedAt: nil), babyImage: nil, babyImageUrl: nil)) {
                Text("查看支付页")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DesignTokens.Colors.success)
                    .cornerRadius(22)
            }

            NavigationLink(destination: GeneratingView(book: MockService.shared.mockBooks[0], order: BackendOrder(id: "test-order", deviceId: "test", bookId: "Book001", bookName: "《这是我》", amount: 9.9, status: "GENERATING", createdAt: "2026-06-24T10:00:00Z", updatedAt: nil))) {
                Text("查看生成中页")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#D4A574"))
                    .cornerRadius(22)
            }

            NavigationLink(destination: CompleteView(book: MockService.shared.mockBooks[0], order: BackendOrder(id: "test-order", deviceId: "test", bookId: "Book001", bookName: "《这是我》", amount: 9.9, status: "SUCCESS", createdAt: "2026-06-24T10:00:00Z", updatedAt: nil), task: BackendTask(id: "test-task", orderId: "test-order", status: "COMPLETED", progress: 100, resultUrl: "https://example.com/generated.png", errorMessage: nil, createdAt: "2026-06-24T10:01:00Z", updatedAt: "2026-06-24T10:02:00Z"))) {
                Text("查看完成页")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DesignTokens.Colors.secondaryText)
                    .cornerRadius(22)
            }
        }
        .padding(.horizontal, DesignTokens.Layout.pagePadding)
        .padding(.top, 32)
    }
}

    // MARK: - 绘本轮播卡片
struct BookCarouselCard: View {
    let book: Book
    @State private var showDetail = false

    var body: some View {
        Button(action: {
            showDetail = true
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
                VStack(spacing: 4) {
                    Text("《\(book.name)》")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    Text("\(book.pageCount)页")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, DesignTokens.Layout.pagePadding)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(isPresented: $showDetail) {
            BookDetailView(book: book)
        }
    }

    // 加载封面图片
    private func loadCoverImage() -> Image? {
        #if os(iOS)
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
    @State private var navigateToPayment = false
    @State private var isCreatingOrder = false
    @State private var isUploadingImage = false
    @State private var createdOrder: BackendOrder?
    @State private var uploadedImageUrl: String?

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
        .navigationDestination(isPresented: $navigateToPayment) {
            if let order = createdOrder {
                #if canImport(UIKit)
                PaymentView(book: book, order: order, babyImage: selectedImage, babyImageUrl: uploadedImageUrl)
                #else
                PaymentView(book: book, order: order, babyImage: nil, babyImageUrl: uploadedImageUrl)
                #endif
            }
        }
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isUploadingImage || isCreatingOrder {
                LoadingOverlay(message: isUploadingImage ? "正在上传照片..." : "正在创建订单...")
            }
        }
    }

    private var uploadSheetContent: some View {
        VStack(spacing: 0) {
            // 拖拽指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignTokens.Colors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 16)

            // 关闭按钮 + 标题
            HStack {
                Text("请上传1张宝宝照片")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primaryText)
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
                    Text("建议照片")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    VStack(alignment: .leading, spacing: 10) {
                        CheckItem(text: "正脸清晰")
                        CheckItem(text: "光线充足")
                        CheckItem(text: "无滤镜遮挡")
                    }
                }

                // 示例照片
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(DesignTokens.Colors.secondary.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(DesignTokens.Colors.primary.opacity(0.3))
                }
                .overlay(
                    Text("示例")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(10)
                        .offset(x: 0, y: -42)
                )
            }
            .padding(.horizontal, DesignTokens.Layout.pagePadding)
            .padding(.top, 36)

            // 按钮：拍照（次按钮）+ 从相册选择（主按钮）
            HStack(spacing: 12) {
                // 拍照按钮（次按钮样式：浅色底黑字）
                Button(action: {}) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.primaryText)
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
                    simulateFaceDetection()
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
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
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
            if let newItem { loadImage(from: newItem) }
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
                    simulateFaceDetection()
                case .success(nil):
                    errorMessage = "无法读取图片"; showError = true; isAnalyzing = false
                case .failure(let error):
                    errorMessage = "加载失败: \(error.localizedDescription)"; showError = true; isAnalyzing = false
                }
            }
        }
    }

    private func simulateFaceDetection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnalyzing = false; faceDetected = true
            uploadImageAndCreateOrder()
        }
    }

    private func uploadImageAndCreateOrder() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isUploadingImage = true

        Task {
            do {
                let imageUrl = try await ImageUploadService.shared.uploadImage(image)
                uploadedImageUrl = imageUrl

                await MainActor.run {
                    isUploadingImage = false
                }

                createOrder(imageUrl: imageUrl)
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
                    navigateToPayment = true
                }
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
                    navigateToPayment = true
                }
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

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}