import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 上传照片页面（接入真实 API）
struct UploadPhotoView: View {
    let book: Book
    @State private var selectedPhoto: PhotosPickerItem? = nil
    #if canImport(UIKit)
    @State private var selectedImage: UIImage? = nil
    #endif
    @State private var isAnalyzing = false
    @State private var faceDetected = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToPayment = false
    @State private var showSheet = false
    @State private var isCreatingOrder = false
    @State private var isUploadingImage = false
    @State private var createdOrder: BackendOrder?
    @State private var uploadedImageUrl: String?

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#222222"))
                    }
                    Spacer()
                    Text("《\(book.name)》")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#222222"))
                    Spacer()
                    Button(action: { showSheet = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#999999"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Text("绘本示例")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F28C28"))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // 绘本预览
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)

                    #if canImport(UIKit)
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "person.crop.square.fill")
                            .font(.system(size: 100))
                            .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
                    }
                    #else
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
                    #endif
                }
                .frame(width: 200, height: 200)
                .padding(.top, 8)

                // 分页
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "#999999"))
                    }
                    Text("第 1 / \(book.pageCount) 页")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(hex: "#999999"))
                    }
                }
                .padding(.top, 8)

                Spacer()

                // 底部半浮层
                uploadSheet
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
    }

    private var uploadSheet: some View {
        VStack(spacing: 0) {
            // 拖拽指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#E5E5E5"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                Text("请上传")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Text("正脸照")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#F28C28"))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            HStack(spacing: 20) {
                // 建议照片
                VStack(alignment: .leading, spacing: 8) {
                    Text("建议照片")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))

                    VStack(alignment: .leading, spacing: 6) {
                        CheckItem(text: "正脸清晰")
                        CheckItem(text: "光线充足")
                        CheckItem(text: "无滤镜遮挡")
                    }
                }

                // 示例照片
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#FFF5E6"))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#F28C28").opacity(0.3))
                }
                .overlay(
                    Text("示例")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#F28C28"))
                        .cornerRadius(8)
                        .offset(x: 0, y: -35)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // 按钮
            HStack(spacing: 12) {
                // 模拟器环境：使用普通按钮模拟照片选择
                #if targetEnvironment(simulator)
                Button(action: {
                    // 模拟选择照片：使用示例宝宝照片
                    #if canImport(UIKit)
                    if let image = UIImage(named: "babyimage", in: Bundle.main, compatibleWith: nil) {
                        selectedImage = image
                    } else {
                        // 如果找不到图片，创建一个纯色图片作为占位
                        selectedImage = createPlaceholderImage()
                    }
                    simulateFaceDetection()
                    #endif
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#FFF5E6"))
                    .cornerRadius(22)
                }
                #else
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#FFF5E6"))
                    .cornerRadius(22)
                }
                #endif

                Button(action: {}) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#F28C28"))
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // 底部插画
            HStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#8BC34A").opacity(0.5))
                Image(systemName: "teddybear.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#D4A574"))
                Image(systemName: "building.blocks.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#F6D7A7"))
            }
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -4)
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
            // 检测到人脸后，先上传图片，再创建订单
            uploadImageAndCreateOrder()
        }
    }

    private func uploadImageAndCreateOrder() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isUploadingImage = true

        Task {
            do {
                // 1. 上传宝宝照片到后端
                let imageUrl = try await ImageUploadService.shared.uploadImage(image)
                uploadedImageUrl = imageUrl

                await MainActor.run {
                    isUploadingImage = false
                }

                // 2. 创建订单（携带图片 URL）
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
        // 非 UIKit 平台直接创建订单（无图片上传）
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
                // 模拟器环境：直接使用模拟订单，跳过真实 API 调用
                #if targetEnvironment(simulator)
                try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟 1 秒网络延迟
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
                // 真机环境：调用真实后端 API
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

#Preview {
    NavigationStack {
        UploadPhotoView(book: MockService.shared.mockBooks[0])
    }
}

// MARK: - 辅助函数
#if canImport(UIKit)
private func createPlaceholderImage() -> UIImage {
    let size = CGSize(width: 200, height: 200)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }

    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor(red: 0.95, green: 0.55, blue: 0.16, alpha: 1.0).cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    // 绘制宝宝图标
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
