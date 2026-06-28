import SwiftUI
import StoreKit

// MARK: - 截图验收测试视图
struct ScreenshotTestView: View {
    @State private var showOrderRestoreAlert = false
    @State private var showPaymentConfirmError = false
    @State private var showGeneratingTimeout = false
    @State private var showPhotoPermissionDenied = false
    @State private var showSavePermissionDenied = false
    @State private var showDownloadSuccess = false
    @State private var showRefundAlert = false
    @State private var showFaceDetectionError = false

    var body: some View {
        NavigationStack {
            List {
                Section("P0 - 订单恢复") {
                    Button("显示订单恢复 Alert") {
                        showOrderRestoreAlert = true
                    }
                }

                Section("P1 - 支付确认") {
                    Button("显示支付确认失败 Alert") {
                        showPaymentConfirmError = true
                    }
                }

                Section("P1 - 生成超时") {
                    Button("显示生成超时 Alert") {
                        showGeneratingTimeout = true
                    }
                }

                Section("P1 - 相册权限") {
                    Button("显示相册权限拒绝 Alert") {
                        showPhotoPermissionDenied = true
                    }
                }

                Section("P1 - 保存权限") {
                    Button("显示保存权限拒绝 Alert") {
                        showSavePermissionDenied = true
                    }
                }

                Section("P1 - 下载成功") {
                    Button("显示下载成功状态") {
                        showDownloadSuccess = true
                    }
                }
                Section("P2 - 取消退款") {
                    Button("显示取消退款 Alert") {
                        showRefundAlert = true
                    }
                }

                Section("P2 - 人脸检测") {
                    Button("显示人脸检测失败 Alert") {
                        showFaceDetectionError = true
                    }
                }
            }
            .navigationTitle("截图验收")
            .onAppear {
                // 自动显示下载成功状态用于截图
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showDownloadSuccess = true
                }
            }
            .alert("恢复订单", isPresented: $showOrderRestoreAlert) {
                Button("取消", role: .cancel) {}
                Button("继续") {}
            } message: {
                Text("检测到未完成的绘本生成订单，是否继续？")
            }
            .alert("提示", isPresented: $showPaymentConfirmError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("无法确认生成任务已创建，请稍后重试或联系客服")
            }
            .alert("提示", isPresented: $showGeneratingTimeout) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("生成超时，请检查网络后重试或联系客服")
            }
            .alert("相册权限", isPresented: $showPhotoPermissionDenied) {
                Button("取消", role: .cancel) {}
                Button("前往设置") {}
            } message: {
                Text("需要访问相册才能选择宝宝照片，请在设置中开启权限")
            }
            .alert("保存权限", isPresented: $showSavePermissionDenied) {
                Button("取消", role: .cancel) {}
                Button("前往设置") {}
            } message: {
                Text("需要访问相册权限才能保存绘本图片")
            }
            .alert("退款提示", isPresented: $showRefundAlert) {
                Button("返回首页") {}
            } message: {
                Text("绘本生成已取消，已支付金额将原路退回（预计 1-3 个工作日到账）。")
            }
            .alert("人脸检测", isPresented: $showFaceDetectionError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("未检测到人脸，请上传宝宝正脸清晰照片")
            }
        }
        .sheet(isPresented: $showDownloadSuccess) {
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
    }
}

// MARK: - 全局通知名称
extension Notification.Name {
    static let resetNavigation = Notification.Name("resetNavigation")
    static let navigateToGenerating = Notification.Name("navigateToGenerating")
}

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
    @StateObject private var orderStatusManager = OrderStatusManager.shared
    let debugMode: String?
    @State private var navigationPath = NavigationPath()
    @State private var restoredOrder: BackendOrder?
    @State private var showRestoredAlert = false

    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                if let mode = debugMode {
                    debugDestination(mode: mode)
                } else {
                    HomeView()
                }
            }
            .environment(\.navPath, $navigationPath)
            .onReceive(NotificationCenter.default.publisher(for: .resetNavigation)) { _ in
                navigationPath.removeLast(navigationPath.count)
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
        .onAppear {
            // App 启动时检查是否有未完成的订单
            restoreOrderIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .orderPaymentRestored)) { notification in
            if let orderId = notification.object as? String {
                handlePaymentRestored(orderId: orderId)
            }
        }
        .alert("恢复订单", isPresented: $showRestoredAlert) {
            Button("继续") {
                if let order = restoredOrder {
                    navigateToGenerating(order: order)
                }
            }
        } message: {
            Text("检测到未完成的绘本生成订单，是否继续？")
        }
    }

    // MARK: - 订单恢复逻辑
    private func restoreOrderIfNeeded() {
        guard debugMode == nil else { return } // 调试模式跳过恢复

        Task {
            if let order = await orderStatusManager.restoreOrderIfNeeded() {
                await MainActor.run {
                    self.restoredOrder = order
                    self.showRestoredAlert = true
                }
            }
        }
    }

    private func handlePaymentRestored(orderId: String) {
        Task {
            do {
                let order = try await NetworkService.shared.getOrder(orderId: orderId)
                await MainActor.run {
                    self.restoredOrder = order
                    self.showRestoredAlert = true
                }
            } catch {
                print("获取恢复订单失败: \(error)")
            }
        }
    }

    private func navigateToGenerating(order: BackendOrder) {
        // 根据订单状态导航到对应页面
        guard let book = MockService.shared.mockBooks.first(where: { $0.id == order.bookId }) else { return }

        // 发送通知让 NavigationStack 跳转到生成页
        NotificationCenter.default.post(
            name: .navigateToGenerating,
            object: ["book": book, "order": order]
        )
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
