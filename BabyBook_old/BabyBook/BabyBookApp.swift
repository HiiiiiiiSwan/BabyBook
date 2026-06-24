import SwiftUI
import StoreKit

@main
struct BabyBookApp: App {
    // 初始化 StoreKit 交易监听
    init() {
        PaymentService.shared.listenForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack {
            NavigationStack {
                HomeView()
            }

            // 首次启动引导
            if onboardingManager.showOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            // 隐私提示
            if onboardingManager.showPrivacyNotice {
                PrivacyNoticeView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.showPrivacyNotice)
    }
}
