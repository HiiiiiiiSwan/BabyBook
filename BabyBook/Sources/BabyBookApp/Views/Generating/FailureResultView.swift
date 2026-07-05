import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 生成失败结果页
// 最终生成失败后展示，提供客服二维码作为用户出口
struct FailureResultView: View {
    let book: Book
    let order: BackendOrder
    let taskErrorMessage: String?

    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 失败状态
                VStack(spacing: DesignTokens.Spacing.xl) {
                    failureIcon

                    Text("绘本生成失败")
                        .font(DesignTokens.Typography.h2)
                        .foregroundColor(DesignTokens.Colors.primaryText)

                    Text(displayErrorMessage)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, DesignTokens.Layout.pagePadding)
                }

                Spacer()

                // 客服二维码区域
                qrCodeImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, DesignTokens.Layout.pagePadding)
                    .padding(.bottom, DesignTokens.Spacing.xl)

                // 返回首页
                Button(action: { goBackToHome() }) {
                    Text("返回首页")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Layout.buttonHeight)
                        .background(DesignTokens.Colors.primary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DesignTokens.Layout.pagePadding)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primaryText)
            }
        }
        .task {
            await loadTaskErrorMessage()
        }
        .onDisappear {
            // 离开失败结果页后清除本地未完成订单记录
            OrderStatusManager.shared.clearSavedOrder()
        }
    }

    // MARK: - 失败图标
    private var failureIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#E85D5D").opacity(0.12))
                .frame(width: 120, height: 120)

            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color(hex: "#E85D5D"))
        }
    }

    // MARK: - 客服二维码
    private var qrCodeImage: some View {
        Group {
            #if canImport(UIKit)
            if let uiImage = loadSupportQRImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholderQR
            }
            #else
            placeholderQR
            #endif
        }
    }

    private var placeholderQR: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(DesignTokens.Colors.border)
            .overlay(
                Text("二维码加载失败")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.tertiaryText)
            )
    }

    // MARK: - 展示文案
    private var displayErrorMessage: String {
        if let message = errorMessage ?? taskErrorMessage, !message.isEmpty {
            return "失败原因：\(message)"
        }
        return "绘本生成过程中遇到异常，请添加客服微信协助处理。"
    }

    // MARK: - 加载客服二维码图片
    #if canImport(UIKit)
    private func loadSupportQRImage() -> UIImage? {
        // 优先从 Bundle 资源加载（生产环境）
        if let bundledImage = UIImage(named: "support") {
            return bundledImage
        }
        // 开发环境回退到指定绝对路径
        let devPath = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/design/support.png"
        return UIImage(contentsOfFile: devPath)
    }
    #endif

    // MARK: - 加载任务错误信息
    private func loadTaskErrorMessage() async {
        // 如果已经从生成页传入错误信息，则不再请求
        guard taskErrorMessage == nil || taskErrorMessage?.isEmpty == true else { return }

        do {
            if let task = try await NetworkService.shared.getTaskByOrderId(orderId: order.id) {
                await MainActor.run {
                    self.errorMessage = task.errorMessage
                }
            }
        } catch {
            print("加载任务错误信息失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 返回首页
    private func goBackToHome() {
        #if canImport(UIKit)
        popToRootViewController()
        #endif
        NotificationCenter.default.post(name: .resetNavigation, object: nil)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FailureResultView(
            book: MockService.shared.mockBooks.first(where: { $0.bookId == "Book001" }) ?? MockService.shared.mockBooks[0],
            order: BackendOrder(
                id: "test-order-id",
                deviceId: "test-device",
                bookId: "Book001",
                bookName: "《这是我》",
                amount: 3.0,
                status: "FAILED",
                createdAt: "2026-06-23T10:00:00Z",
                updatedAt: nil
            ),
            taskErrorMessage: "任务执行超时"
        )
    }
}

#if canImport(UIKit)
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
