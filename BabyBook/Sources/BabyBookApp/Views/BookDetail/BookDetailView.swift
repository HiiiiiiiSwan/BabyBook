import SwiftUI

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared
    @State private var showUploadSheet = false
    @State private var showLeaveAppAlert = false
    @State private var currentPageIndex = 0  // 当前展示的页面索引
    @State private var isFlipping = false
    @State private var flipDirection: Bool = true // true = 向右翻，false = 向左翻
    @State private var flipProgress: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    bookPreviewSection
                    bookInfoSection
                    Spacer().frame(height: 180)
                }
            }

            bottomCTA
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#222222"))
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text("《\(book.name)》")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
            }
        }
        #endif
        .overlay {
            if showUploadSheet {
                UploadPhotoSheet(book: book, isPresented: $showUploadSheet)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetNavigation)) { _ in
            showUploadSheet = false
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

    // 页面尺寸计算
    private let pageSize: CGFloat = 163
    private let spineWidth: CGFloat = 2
    private let horizontalPadding: CGFloat = 32

    /// 总页数（包含封面和封底，每页展示2个页面）
    private var totalPreviewPages: Int {
        // pageImages 已包含 0_cover, 1-8, 9（封底），共10张图
        // 双页展示：封面单独一页，内容4页，封底单独一页，共6页
        return (book.pageImages.count + 1) / 2 + 1
    }

    /// 将预览页索引映射到 pageImages 索引
    private func pageImageIndex(for previewIndex: Int) -> Int {
        return previewIndex
    }

    private var bookPreviewSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(DesignTokens.Colors.primary.opacity(0.4))
                    .frame(width: 40, height: 1)

                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(DesignTokens.Colors.primary.opacity(0.6))

                Text("绘本示例")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primaryText)

                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(DesignTokens.Colors.primary.opacity(0.6))

                Rectangle()
                    .fill(DesignTokens.Colors.primary.opacity(0.4))
                    .frame(width: 40, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 双页翻书预览（带翻页动画 + 手势滑动）
            ZStack {
                // 背景书本容器
                HStack(spacing: 0) {
                    // 左页（仅当不是第一页时显示）
                    if currentPageIndex > 0 {
                        let leftImageIndex = pageImageIndex(for: currentPageIndex * 2 - 1)
                        if leftImageIndex >= 0 && leftImageIndex < book.pageImages.count {
                            bookPageView(pageIndex: leftImageIndex, isLeft: true)
                                .frame(width: pageSize, height: pageSize)
                                .zIndex(1)

                            // 书脊
                            Rectangle()
                                .fill(Color(hex: "#E0D8CE"))
                                .frame(width: spineWidth, height: pageSize)
                        }
                    }

                    // 右页
                    let rightImageIndex = pageImageIndex(for: currentPageIndex * 2)
                    if rightImageIndex >= 0 && rightImageIndex < book.pageImages.count {
                        bookPageView(pageIndex: rightImageIndex, isLeft: false)
                            .frame(width: pageSize, height: pageSize)
                            .zIndex(1)
                    }
                }
                .padding(.horizontal, currentPageIndex > 0 ? horizontalPadding : (UIScreen.main.bounds.width - pageSize) / 2)

                // 翻页动画层（覆盖在右页上，向左翻转）
                if isFlipping && flipDirection {
                    // 向前翻页：右页内容翻转覆盖左页
                    HStack(spacing: 0) {
                        if currentPageIndex > 0 || (currentPageIndex == 0 && (currentPageIndex + 1) > 0) {
                            Spacer()
                                .frame(width: currentPageIndex > 0 ? pageSize + spineWidth : 0)

                            let nextLeftImageIndex = pageImageIndex(for: (currentPageIndex + 1) * 2 - 1)
                            if nextLeftImageIndex >= 0 && nextLeftImageIndex < book.pageImages.count {
                                bookPageView(pageIndex: nextLeftImageIndex, isLeft: true)
                                    .frame(width: pageSize, height: pageSize)
                                    .rotation3DEffect(
                                        .degrees(-180 * flipProgress),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .leading,
                                        perspective: 0.3
                                    )
                                    .opacity(flipProgress > 0.5 ? 0 : 1)
                                    .zIndex(2)
                            }
                        }
                    }
                    .padding(.horizontal, currentPageIndex > 0 ? horizontalPadding : (UIScreen.main.bounds.width - pageSize) / 2)
                }

                // 翻页动画层（覆盖在左页上，向右翻转）
                if isFlipping && !flipDirection {
                    // 向后翻页：左页内容翻转覆盖右页
                    HStack(spacing: 0) {
                        let prevRightImageIndex = pageImageIndex(for: (currentPageIndex - 1) * 2)
                        if prevRightImageIndex >= 0 && prevRightImageIndex < book.pageImages.count {
                            bookPageView(pageIndex: prevRightImageIndex, isLeft: false)
                                .frame(width: pageSize, height: pageSize)
                                .rotation3DEffect(
                                    .degrees(180 * flipProgress),
                                    axis: (x: 0, y: 1, z: 0),
                                    anchor: .trailing,
                                    perspective: 0.3
                                )
                                .opacity(flipProgress > 0.5 ? 0 : 1)
                                .zIndex(2)
                        }

                        if currentPageIndex > 1 {
                            Spacer()
                                .frame(width: spineWidth)
                        }
                    }
                    .padding(.horizontal, currentPageIndex > 1 ? horizontalPadding : (UIScreen.main.bounds.width - pageSize) / 2)
                }
            }
            .frame(height: pageSize + 20)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            // 左滑 - 下一页
                            flipPage(forward: true)
                        } else if value.translation.width > threshold {
                            // 右滑 - 上一页
                            flipPage(forward: false)
                        }
                    }
            )

            // 分页指示器
            HStack(spacing: 16) {
                Button(action: {
                    flipPage(forward: false)
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(currentPageIndex > 0 ? Color(hex: "#F28C28") : Color(hex: "#999999"))
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(currentPageIndex == 0 || isFlipping)

                Text("\(currentPageIndex + 1) / \(totalPreviewPages)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#666666"))

                Button(action: {
                    flipPage(forward: true)
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(currentPageIndex < totalPreviewPages - 1 ? Color(hex: "#F28C28") : Color(hex: "#999999"))
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(currentPageIndex == totalPreviewPages - 1 || isFlipping)
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    // 翻页动画
    private func flipPage(forward: Bool) {
        guard !isFlipping else { return }

        if forward && currentPageIndex >= totalPreviewPages - 1 { return }
        if !forward && currentPageIndex <= 0 { return }

        flipDirection = forward
        isFlipping = true
        flipProgress = 0

        withAnimation(.easeInOut(duration: 0.6)) {
            flipProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if forward {
                currentPageIndex += 1
            } else {
                currentPageIndex -= 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isFlipping = false
            flipProgress = 0
        }
    }

    // 单页视图（正方形）
    private func bookPageView(pageIndex: Int, isLeft: Bool) -> some View {
        ZStack {
            if pageIndex == -1 {
                // 封面左侧空白页
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#FFFDF9"))
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#F0E8DE"))
                            Text("封面")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#999999"))
                        }
                    )
            } else if pageIndex >= 0 && pageIndex < book.pageImages.count {
                if let image = loadPageImage(named: book.pageImages[pageIndex]) {
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    pagePlaceholderSmall(name: book.pageImages[pageIndex])
                }
            } else {
                // 空白页
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#FFFDF9"))
            }
        }
        .frame(width: pageSize, height: pageSize)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: isLeft ? -2 : 2,
            y: 2
        )
    }

    // 小占位图
    private func pagePlaceholderSmall(name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)

            VStack(spacing: 4) {
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
                Text("\(name)")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#999999"))
            }
        }
    }

    // 页面占位图（大）
    private func pagePlaceholder(name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

            VStack(spacing: 8) {
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
                Text("\(name)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 固定图片：关于绘本 + 获取流程
            if let directionsImage = loadDirectionsImage() {
                directionsImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 0)
            } else {
                // 图片加载失败时的占位
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#F5F0E8"))
                    .frame(height: 200)
                    .overlay(
                        Text("图片加载中...")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#999999"))
                    )
                    .padding(.horizontal, 24)
            }
        }
        .padding(.top, 24)
    }

    // 加载固定说明图片
    private func loadDirectionsImage() -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(named: "directions") {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // 一键定制按钮：样式与首页一致
                ZStack(alignment: .bottom) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showUploadSheet = true
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

                    Text("仅需\(displayPrice)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E85D5D"))
                        .cornerRadius(12)
                        .offset(x: 80, y: -20)
                }
                .padding(.top, 16)

                // 获取实体书按钮
                Button(action: { showLeaveAppAlert = true }) {
                    HStack(spacing: 4) {
                        Text("获取实体书")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#666666"))
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
            .background(Color(hex: "#FFF9F2"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - 打开实体书微店
    private func openPhysicalBookStore() {
        let storeURL = URL(string: "https://weidian.com/?userid=1868613735")!

        #if os(iOS)
        UIApplication.shared.open(storeURL)
        #endif
    }

    // 加载绘本页面图片（优先从 Bundle 读取，回退到绝对路径）
    private func loadPageImage(named: String) -> Image? {
        #if os(iOS)
        let bundlePath = pageBundlePath(for: named)
        if let uiImage = UIImage(named: bundlePath, in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }

        let filePath = pageFilePath(for: named)
        if let uiImage = UIImage(contentsOfFile: filePath) {
            return Image(uiImage: uiImage)
        }
        #else
        let filePath = pageFilePath(for: named)
        if let nsImage = NSImage(contentsOfFile: filePath) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }

    private var displayPrice: String {
        if let displayPrice = paymentService.product(for: book.bookId)?.displayPrice {
            return "¥\(displayPrice)"
        }
        return "¥\(String(format: "%.1f", book.price))"
    }

    private func pageBundlePath(for named: String) -> String {
        switch book.bookId {
        case "Book001":
            return "self_intro/\(named)"
        case "Book002":
            return "dream_job/\(named)"
        case "Book003":
            return "color_recognition/\(named)"
        default:
            return "self_intro/\(named)"
        }
    }

    private func pageFilePath(for named: String) -> String {
        let basePath: String
        switch book.bookId {
        case "Book001":
            basePath = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/templates/self_intro/pages"
        case "Book002":
            basePath = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/templates/dream_job/pages"
        case "Book003":
            basePath = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/templates/color_recognition/pages"
        default:
            basePath = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/templates/self_intro/pages"
        }
        return "\(basePath)/\(named).png"
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#F28C28"))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#999999"))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        BookDetailView(book: MockService.shared.mockBooks[0])
    }
}
