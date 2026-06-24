import SwiftUI
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 支付页面（接入 StoreKit2 真实支付）
struct PaymentView: View {
    let book: Book
    let order: BackendOrder
    #if canImport(UIKit)
    let babyImage: UIImage?
    #else
    let babyImage: Image?
    #endif
    let babyImageUrl: String?  // 已上传的宝宝照片 URL

    @StateObject private var paymentService = PaymentService.shared
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToGenerating = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题
                headerSection

                // 订单信息
                orderInfoSection

                // 支付方式
                paymentMethodSection

                Spacer()

                // 底部支付按钮
                payButton
            }
        }
        .navigationTitle("支付")
        .navigationDestination(isPresented: $navigateToGenerating) {
            GeneratingView(book: book, order: order)
        }
        .alert("支付失败", isPresented: $showError) {
            Button("重试", role: .none) { startPayment() }
            Button("取消", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // 页面加载时获取产品信息
            await paymentService.loadProducts()
        }
    }

    // MARK: - 顶部标题
    private var headerSection: some View {
        Text("支付")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: "#222222"))
            .padding(.top, 20)
            .padding(.bottom, 24)
    }

    // MARK: - 订单信息
    private var orderInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("订单信息")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))

            // 绘本信息卡片
            HStack(spacing: 16) {
                // 封面缩略图
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#FFF5E6"),
                                    Color(hex: "#FFE8CC")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 100)

                    Image(systemName: "book.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "#F28C28").opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text("\(book.pageCount)页 · 专属定制")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))

                    Text("¥\(String(format: "%.2f", order.amount))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#F28C28"))
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // 价格明细
            VStack(spacing: 12) {
                HStack {
                    Text("绘本定制服务")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))
                    Spacer()
                    Text("¥\(String(format: "%.2f", order.amount))")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#222222"))
                }

                HStack {
                    Text("优惠")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))
                    Spacer()
                    Text("-¥0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8BC34A"))
                }

                Divider()
                    .background(Color(hex: "#F0E8DE"))

                HStack {
                    Text("实付金额")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))
                    Spacer()
                    Text("¥\(String(format: "%.2f", order.amount))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#F28C28"))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 支付方式
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支付方式")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))

            // Apple Pay 选项
            HStack(spacing: 16) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#222222"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Pay")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text("安全快捷支付")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#F28C28").opacity(0.3), lineWidth: 2)
            )

            // 安全提示
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8BC34A"))

                Text("支付信息由 Apple 加密保护，我们不会保存您的支付信息")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - 支付按钮
    private var payButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(hex: "#F0E8DE"))

            Button(action: {
                startPayment()
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "apple.logo")
                        Text("Apple Pay 支付")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isProcessing
                        ? Color(hex: "#F28C28").opacity(0.6)
                        : Color(hex: "#F28C28")
                )
                .cornerRadius(24)
            }
            .disabled(isProcessing)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(hex: "#FFF9F2"))
        }
    }

    // MARK: - 处理支付
    private func startPayment() {
        isProcessing = true

        Task {
            do {
                // 模拟器环境：跳过真实支付，直接模拟成功
                #if targetEnvironment(simulator)
                try await Task.sleep(nanoseconds: 1_500_000_000) // 模拟 1.5 秒支付延迟
                await MainActor.run {
                    isProcessing = false
                    navigateToGenerating = true
                }
                #else
                // 真机环境：使用 StoreKit2 进行真实支付
                let _ = try await paymentService.purchase(
                    bookId: book.bookId,
                    orderId: order.id
                )

                // 支付成功后，如果有图片 URL，更新到订单
                if let imageUrl = babyImageUrl {
                    try? await NetworkService.shared.updateOrderImage(
                        orderId: order.id,
                        imageUrl: imageUrl
                    )
                }

                await MainActor.run {
                    isProcessing = false
                    navigateToGenerating = true
                }
                #endif
            } catch PaymentError.userCancelled {
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PaymentView(
            book: MockService.shared.mockBooks[0],
            order: BackendOrder(
                id: "test-order-id",
                deviceId: "test-device",
                bookId: "Book001",
                bookName: "《这是我》",
                amount: 12.99,
                status: "UNPAID",
                createdAt: "2026-06-23T10:00:00Z",
                updatedAt: nil
            ),
            babyImage: nil,
            babyImageUrl: nil
        )
    }
}
