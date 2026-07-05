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
    @State private var showCannotRefundAlert = false
    @State private var showCancelAlert = false
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
                    Button("显示取消确认 Alert") {
                        showCancelAlert = true
                    }
                    Button("显示取消成功 Alert（无法退款）") {
                        showCannotRefundAlert = true
                    }
                }
            }
            .navigationTitle("截图验收")
        }
        .alert("绘本生成中", isPresented: $showOrderRestoreAlert) {
            Button("取消", role: .cancel) {}
            Button("查看") {}
        } message: {
            Text("检测到有未完成的绘本，点击可查看最新进展")
        }
        .alert("提示", isPresented: $showPaymentConfirmError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("无法确认生成任务已创建，请稍后重试")
        }
        .alert("提示", isPresented: $showGeneratingTimeout) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("生成超时，请检查网络后重试")
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
        .alert("取消生成", isPresented: $showCancelAlert) {
            Button("继续生成", role: .cancel) {}
            Button("确认取消", role: .destructive) {}
        } message: {
            Text("图片生成费用订单已生成，无法退款，是否确认取消？")
        }
        .alert("提示", isPresented: $showCannotRefundAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("绘本生成已取消。由于图片生成服务已调用，订单费用无法退回。")
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
    }
}

// MARK: - 全局通知名称
extension Notification.Name {
    static let resetNavigation = Notification.Name("resetNavigation")
    static let navigateToGenerating = Notification.Name("navigateToGenerating")
    static let navigateToFailureResult = Notification.Name("navigateToFailureResult")
}

@main
struct BabyBookApp: App {
    // 调试模式：直接跳转到指定页面
    // 可选值：home, detail, upload, payment, generating, complete, mybooks
    // 上线前必须设为 nil
    private let debugMode: String? = nil

    init() {
        PaymentService.shared.listenForTransactions()
        // App 启动时预加载 IAP 产品，避免从首页弹窗直接支付时产品列表为空
        Task {
            await PaymentService.shared.loadProducts()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(debugMode: debugMode)
        }
    }
}

struct ContentView: View {
    @StateObject private var orderStatusManager = OrderStatusManager.shared
    let debugMode: String?
    @State private var navigationPath = NavigationPath()
    @State private var restoredOrder: BackendOrder?
    @State private var showRestoredAlert = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .active

    var body: some View {
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
        .onAppear {
            // App 启动时检查是否有未完成的订单
            restoreOrderIfNeeded()
        }
        .onChange(of: scenePhase) { newPhase in
            // 只有真正从后台返回前台时才检查（避免页面内切换 active 时误触发）
            if newPhase == .active && self.previousScenePhase == .background {
                restoreOrderIfNeeded()
            }
            self.previousScenePhase = newPhase
        }
        .onReceive(NotificationCenter.default.publisher(for: .orderPaymentRestored)) { notification in
            if let orderId = notification.object as? String {
                handlePaymentRestored(orderId: orderId)
            }
        }
        .alert("绘本生成中", isPresented: $showRestoredAlert) {
            Button("查看") {
                if let order = restoredOrder {
                    navigateToGenerating(order: order)
                }
            }
        } message: {
            Text("检测到有未完成的绘本，点击可查看最新进展")
        }
    }

    // MARK: - 订单恢复逻辑
    private func restoreOrderIfNeeded() {
        guard debugMode == nil else { return } // 调试模式跳过恢复

        Task {
            print("[订单恢复] 开始检查未完成订单...")
            if let order = await orderStatusManager.restoreOrderIfNeeded() {
                print("[订单恢复] 发现未完成订单: \(order.id), 状态: \(order.status)")
                await MainActor.run {
                    self.restoredOrder = order
                    self.showRestoredAlert = true
                }
            } else {
                print("[订单恢复] 没有需要恢复的订单")
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
        // 恢复弹窗统一进入生成中页，再由生成中页根据状态内跳完成页/失败页
        guard let book = MockService.shared.mockBooks.first(where: { $0.bookId == order.bookId }) else { return }

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
                    amount: 3.0,
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
                    amount: 3.0,
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
                    amount: 3.0,
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
                ),
                preloadedImage: nil
            )
        case "mybooks":
            MyBooksView()
        case "screenshot":
            ScreenshotTestView()
        default:
            HomeView()
        }
    }
}
