import SwiftUI
import StoreKit

@main
struct BabyBookApp: App {
    // 调试模式：直接跳转到指定页面
    // 可选值：home, detail, upload, payment, generating, complete, mybooks
    private let debugMode: String? = nil

    init() {
        PaymentService.shared.listenForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(debugMode: debugMode)
        }
    }
}

struct ContentView: View {
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    let debugMode: String?

    var body: some View {
        ZStack {
            NavigationStack {
                if let mode = debugMode {
                    debugDestination(mode: mode)
                } else {
                    HomeView()
                }
            }

            if onboardingManager.showOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            if onboardingManager.showPrivacyNotice {
                PrivacyNoticeView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.showPrivacyNotice)
    }

    @ViewBuilder
    private func debugDestination(mode: String) -> some View {
        switch mode {
        case "home":
            HomeView()
        case "detail":
            BookDetailView(book: MockService.shared.mockBooks[0])
        case "upload":
            UploadPhotoView(book: MockService.shared.mockBooks[0])
        case "payment":
            PaymentView(
                book: MockService.shared.mockBooks[0],
                order: BackendOrder(
                    id: "test-order",
                    deviceId: "test-device",
                    bookId: "Book001",
                    bookName: "《这是我》",
                    amount: 9.9,
                    status: "UNPAID",
                    createdAt: "2026-06-24T10:00:00Z",
                    updatedAt: nil
                ),
                babyImage: nil,
                babyImageUrl: nil
            )
        case "generating":
            GeneratingView(
                book: MockService.shared.mockBooks[0],
                order: BackendOrder(
                    id: "test-order",
                    deviceId: "test-device",
                    bookId: "Book001",
                    bookName: "《这是我》",
                    amount: 9.9,
                    status: "GENERATING",
                    createdAt: "2026-06-24T10:00:00Z",
                    updatedAt: nil
                )
            )
        case "complete":
            CompleteView(
                book: MockService.shared.mockBooks[0],
                order: BackendOrder(
                    id: "test-order",
                    deviceId: "test-device",
                    bookId: "Book001",
                    bookName: "《这是我》",
                    amount: 9.9,
                    status: "SUCCESS",
                    createdAt: "2026-06-24T10:00:00Z",
                    updatedAt: nil
                ),
                task: BackendTask(
                    id: "test-task",
                    orderId: "test-order",
                    status: "COMPLETED",
                    progress: 100,
                    resultUrl: "https://example.com/generated.png",
                    errorMessage: nil,
                    createdAt: "2026-06-24T10:01:00Z",
                    updatedAt: "2026-06-24T10:02:00Z"
                )
            )
        case "mybooks":
            MyBooksView()
        default:
            HomeView()
        }
    }
}
