import SwiftUI

// MARK: - 首次启动引导管理
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasShownOnboardingKey = "com.babybook.hasShownOnboarding"
    private let hasShownPrivacyKey = "com.babybook.hasShownPrivacy"

    @Published var showOnboarding: Bool = false
    @Published var showPrivacyNotice: Bool = false

    private init() {
        // 检查是否已显示过引导
        let hasShown = UserDefaults.standard.bool(forKey: hasShownOnboardingKey)
        let hasShownPrivacy = UserDefaults.standard.bool(forKey: hasShownPrivacyKey)

        if !hasShown {
            showOnboarding = true
        } else if !hasShownPrivacy {
            showPrivacyNotice = true
        }
    }

    /// 完成引导
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasShownOnboardingKey)
        showOnboarding = false
        showPrivacyNotice = true
    }

    /// 完成隐私提示
    func completePrivacyNotice() {
        UserDefaults.standard.set(true, forKey: hasShownPrivacyKey)
        showPrivacyNotice = false
    }

    /// 重置（调试用）
    func reset() {
        UserDefaults.standard.removeObject(forKey: hasShownOnboardingKey)
        UserDefaults.standard.removeObject(forKey: hasShownPrivacyKey)
        showOnboarding = true
        showPrivacyNotice = false
    }
}

// MARK: - 首次启动引导视图
struct OnboardingView: View {
    @ObservedObject private var manager = OnboardingManager.shared
    @State private var currentPage = 0

    let pages = [
        OnboardingPage(
            image: "book.closed.fill",
            title: "欢迎来到宝贝绘本",
            description: "只需上传 1 张宝宝照片\n即可生成专属定制绘本",
            color: "#F28C28"
        ),
        OnboardingPage(
            image: "photo.on.rectangle.angled",
            title: "上传宝宝照片",
            description: "选择一张清晰的正脸照\nAI 将让宝宝成为绘本主角",
            color: "#8BC34A"
        ),
        OnboardingPage(
            image: "wand.and.stars",
            title: "AI 智能生成",
            description: "1 分钟内生成精美绘本\n专属定制，独一无二",
            color: "#F28C28"
        ),
        OnboardingPage(
            image: "square.and.arrow.down",
            title: "保存与分享",
            description: "下载 PDF 电子版\n或获取精美实体书",
            color: "#D4A574"
        )
    ]

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .frame(maxHeight: .infinity)

                // 分页指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color(hex: "#F28C28") : Color(hex: "#E5E5E5"))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // 按钮
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        manager.completeOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#F28C28"))
                        .cornerRadius(999)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 单页引导视图
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 插图
            ZStack {
                Circle()
                    .fill(Color(hex: page.color).opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: page.image)
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: page.color))
            }

            // 标题
            Text(page.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))
                .multilineTextAlignment(.center)

            // 描述
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#666666"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - 引导页数据
struct OnboardingPage {
    let image: String
    let title: String
    let description: String
    let color: String
}

// MARK: - 隐私提示弹窗
struct PrivacyNoticeView: View {
    @ObservedObject private var manager = OnboardingManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景不关闭，必须点击按钮
                }

            VStack(spacing: 0) {
                // 图标
                Image(systemName: "shield.checkered.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#8BC34A"))
                    .padding(.top, 32)

                // 标题
                Text("数据隐私保护")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                    .padding(.top, 16)

                // 说明内容
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyItem(
                        icon: "photo",
                        title: "宝宝照片",
                        description: "仅用于 AI 生成，生成完成后立即删除，不保存"
                    )

                    PrivacyItem(
                        icon: "doc",
                        title: "绘本文件",
                        description: "仅保存在您的设备本地，不上传云端"
                    )

                    PrivacyItem(
                        icon: "iphone",
                        title: "本地存储",
                        description: "绘本仅保存在当前设备，卸载后无法恢复，请及时保存"
                    )

                    PrivacyItem(
                        icon: "lock.fill",
                        title: "订单信息",
                        description: "仅保存订单记录用于售后服务，不包含任何照片"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // 按钮
                Button(action: {
                    manager.completePrivacyNotice()
                }) {
                    Text("我知道了")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#F28C28"))
                        .cornerRadius(24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .cornerRadius(32)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - 隐私项视图
struct PrivacyItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#F28C28"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#666666"))
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
