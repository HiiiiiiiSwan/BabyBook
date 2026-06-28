import SwiftUI
#if canImport(UIKit)
import UIKit
import AVFoundation

// MARK: - 相机拍照视图
/// 使用 UIKit AVFoundation 实现的相机拍照功能
/// 支持实时预览、拍照、切换前后摄像头
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    var onCancel: (() -> Void)?

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func didCaptureImage(_ image: UIImage) {
            parent.capturedImage = image
            parent.isPresented = false
        }

        func didCancel() {
            parent.onCancel?()
            parent.isPresented = false
        }
    }
}

// MARK: - 相机视图控制器协议
protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didCancel()
}

// MARK: - 相机视图控制器
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isUsingFrontCamera = false

    // UI 元素
    private let captureButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let switchButton = UIButton(type: .system)
    private let focusView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermission()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    // MARK: - 权限检查
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            break
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "相机权限",
            message: "需要访问相机才能拍摄宝宝照片，请在设置中开启权限",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.delegate?.didCancel()
        })
        alert.addAction(UIAlertAction(title: "前往设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - 相机设置
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session

        guard let device = getCameraDevice() else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }

            // 设置预览层
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer

            // 开始运行
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            print("相机设置失败: \(error)")
        }
    }

    private func getCameraDevice() -> AVCaptureDevice? {
        if isUsingFrontCamera {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        } else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
    }

    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .black

        // 拍照按钮（底部居中）
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        // 取消按钮（左下角）
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        // 切换摄像头按钮（右下角）
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        switchButton.tintColor = .white
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        view.addSubview(switchButton)

        // 对焦框
        focusView.translatesAutoresizingMaskIntoConstraints = false
        focusView.layer.borderWidth = 1.5
        focusView.layer.borderColor = UIColor(cameraHex: "#F28C28").cgColor
        focusView.backgroundColor = .clear
        focusView.isHidden = true
        view.addSubview(focusView)

        // 约束
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),

            switchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            switchButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchButton.widthAnchor.constraint(equalToConstant: 44),
            switchButton.heightAnchor.constraint(equalToConstant: 44),

            focusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            focusView.widthAnchor.constraint(equalToConstant: 80),
            focusView.heightAnchor.constraint(equalToConstant: 80)
        ])

        // 点击对焦手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapFocus(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - 操作
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelTapped() {
        delegate?.didCancel()
    }

    @objc private func switchCamera() {
        isUsingFrontCamera.toggle()

        captureSession?.beginConfiguration()

        // 移除现有输入
        if let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput {
            captureSession?.removeInput(currentInput)
        }

        // 添加新输入
        guard let newDevice = getCameraDevice(),
              let newInput = try? AVCaptureDeviceInput(device: newDevice),
              captureSession?.canAddInput(newInput) == true else {
            captureSession?.commitConfiguration()
            return
        }

        captureSession?.addInput(newInput)
        captureSession?.commitConfiguration()
    }

    @objc private func handleTapFocus(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)

        focusView.center = point
        focusView.isHidden = false
        focusView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.transform = .identity
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusView.isHidden = true
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        delegate?.didCaptureImage(image)
    }
}

// MARK: - UIColor Hex 扩展（CameraView 专用）
extension UIColor {
    convenience init(cameraHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
#endif
