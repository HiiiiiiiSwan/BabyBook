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
    @State private var navigateToGenerating = false
    @State private var navigateToFailureResult = false
    @State private var isProcessingPayment = false
    @State private var showSheet = false
    @State private var showPhotoPicker = false
    @State private var isCreatingOrder = false
    @State private var isUploadingImage = false
    @State private var createdOrder: BackendOrder?
    @State private var uploadedImageUrl: String?
    @StateObject private var paymentService = PaymentService.shared
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showCamera = false
    @State private var showFaceDetectionError = false
    @State private var faceDetectionErrorMessage = ""

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
            .navigationDestination(isPresented: $navigateToGenerating) {
                if let order = createdOrder {
                    GeneratingView(book: book, order: order)
                }
            }
            .navigationDestination(isPresented: $navigateToFailureResult) {
                if let order = createdOrder {
                    FailureResultView(book: book, order: BackendOrder(
                        id: order.id,
                        deviceId: order.deviceId,
                        bookId: order.bookId,
                        bookName: order.bookName,
                        amount: order.amount,
                        status: "FAILED",
                        createdAt: order.createdAt,
                        updatedAt: order.updatedAt
                    ), taskErrorMessage: "支付成功但服务器连接异常，请添加客服微信协助处理")
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("相机权限", isPresented: $showPermissionAlert) {
                Button("取消", role: .cancel) {}
                Button("前往设置") {
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }
            } message: {
                Text(permissionAlertMessage)
            }
            .overlay {
                if isUploadingImage || isCreatingOrder || isProcessingPayment {
                    LoadingOverlay(message: overlayMessage)
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
                    performFaceDetection()
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
                Button(action: {
                    showPhotoPicker = true
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
                #endif

                Button(action: { checkCameraPermission() }) {
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
        .sheet(isPresented: $showPhotoPicker) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("选择照片")
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            if let newItem { loadImage(from: newItem) }
        }
        .sheet(isPresented: $showCamera) {
            #if canImport(UIKit)
            CameraView(
                capturedImage: $selectedImage,
                isPresented: $showCamera,
                onCapture: { _ in
                    performFaceDetection()
                },
                onCancel: {}
            )
            #endif
        }
        .alert("人脸检测", isPresented: $showFaceDetectionError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(faceDetectionErrorMessage)
        }
    }

    private func performFaceDetection() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isAnalyzing = true
        faceDetected = false

        Task {
            let result = await FaceDetectionService.shared.detectFaces(in: image)
            await MainActor.run {
                isAnalyzing = false
                switch result {
                case .success:
                    faceDetected = true
                    uploadImageAndCreateOrder()
                case .noFaceDetected:
                    faceDetectionErrorMessage = "未检测到人脸，请上传宝宝正脸清晰照片"
                    showFaceDetectionError = true
                case .multipleFacesDetected(let count):
                    faceDetectionErrorMessage = "检测到 \(count) 张人脸，请只上传1张宝宝照片"
                    showFaceDetectionError = true
                case .failed(let error):
                    faceDetectionErrorMessage = "人脸检测失败: \(error.localizedDescription)"
                    showFaceDetectionError = true
                }
            }
        }
        #else
        // 非 UIKit 平台跳过人脸检测
        faceDetected = true
        uploadImageAndCreateOrder()
        #endif
    }

    private func checkCameraPermission() {
        #if canImport(UIKit)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .denied, .restricted:
            permissionAlertMessage = "需要访问相机才能拍摄宝宝照片，请在设置中开启权限"
            showPermissionAlert = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        permissionAlertMessage = "需要访问相机才能拍摄宝宝照片，请在设置中开启权限"
                        showPermissionAlert = true
                    }
                }
            }
        @unknown default:
            break
        }
        #endif
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
                    performFaceDetection()
                case .success(nil):
                    errorMessage = "无法读取图片"; showError = true; isAnalyzing = false
                case .failure(let error):
                    errorMessage = "加载失败: \(error.localizedDescription)"; showError = true; isAnalyzing = false
                }
            }
        }
    }

    private func uploadImageAndCreateOrder() {
        #if canImport(UIKit)
        guard let image = selectedImage else { return }
        isUploadingImage = true

        Task {
            do {
                #if targetEnvironment(simulator)
                // 模拟器环境：跳过真实上传，使用 mock 图片 URL
                try await Task.sleep(nanoseconds: 800_000_000)
                let mockImageUrl = "https://mock.babybook.app/images/baby_\(Int.random(in: 1000...9999)).jpg"
                uploadedImageUrl = mockImageUrl
                await MainActor.run {
                    isUploadingImage = false
                }
                createOrder(imageUrl: mockImageUrl)
                #else
                // 1. 上传宝宝照片到后端
                let imageUrl = try await ImageUploadService.shared.uploadImage(image)
                uploadedImageUrl = imageUrl

                await MainActor.run {
                    isUploadingImage = false
                }

                // 2. 创建订单（携带图片 URL）
                createOrder(imageUrl: imageUrl)
                #endif
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

    private var overlayMessage: String {
        if isUploadingImage {
            return "正在上传照片..."
        } else if isCreatingOrder {
            return "正在创建订单..."
        } else if isProcessingPayment {
            return "正在唤起支付..."
        }
        return ""
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
                }
                // 保存订单到本地（用于崩溃/杀后台后恢复）
                OrderStatusManager.shared.saveCurrentOrder(mockOrder)
                await startPayment(order: mockOrder)
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
                }
                // 保存订单到本地（用于崩溃/杀后台后恢复）
                OrderStatusManager.shared.saveCurrentOrder(order)
                await startPayment(order: order)
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

    private func startPayment(order: BackendOrder) async {
        isProcessingPayment = true
        do {
            #if targetEnvironment(simulator)
            try await Task.sleep(nanoseconds: 1_500_000_000)
            #else
            let _ = try await paymentService.purchase(
                bookId: book.bookId,
                orderId: order.id
            )
            if let imageUrl = uploadedImageUrl {
                try? await NetworkService.shared.updateOrderImage(
                    orderId: order.id,
                    imageUrl: imageUrl
                )
            }
            #endif
            await MainActor.run {
                isProcessingPayment = false

                // 支付成功后立即把本地订单更新为 PAID，
                // 这样即使立刻杀端，恢复时也能识别为已支付的绘本订单。
                if let paidOrder = createdOrder?.updatingStatus(to: "PAID") {
                    OrderStatusManager.shared.currentOrder = paidOrder
                    OrderStatusManager.shared.saveCurrentOrder(paidOrder)
                }

                navigateToGenerating = true
            }
        } catch PaymentError.userCancelled {
            await MainActor.run {
                isProcessingPayment = false
            }
        } catch {
            await MainActor.run {
                isProcessingPayment = false
                if let paymentError = error as? PaymentError,
                   case .paidButServerError = paymentError {
                    // Apple 已扣款，但后端验证/任务创建失败，进入失败结果页联系客服
                    navigateToFailureResult = true
                } else {
                    // Apple 支付阶段失败（未付款成功）
                    errorMessage = error.localizedDescription
                    showError = true
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
