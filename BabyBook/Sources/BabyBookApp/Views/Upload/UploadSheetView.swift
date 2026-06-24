import SwiftUI
import PhotosUI

struct UploadSheetView: View {
    let book: Book
    @Binding var isPresented: Bool
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var isAnalyzing = false
    @State private var faceDetected = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 半透明黑色蒙层
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }

            // 底部弹窗内容
            VStack {
                Spacer()
                uploadSheetContent
                    .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var uploadSheetContent: some View {
        VStack(spacing: 0) {
            // 拖拽指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#E5E5E5"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // 关闭按钮
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#999999"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

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
            .padding(.top, 8)

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
                    #if os(macOS)
                    if let nsImage = NSImage(data: data) {
                        selectedImage = Image(nsImage: nsImage)
                    } else { selectedImage = Image(systemName: "photo") }
                    #else
                    if let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                    } else { selectedImage = Image(systemName: "photo") }
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
        }
    }
}

struct CheckItem: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8BC34A"))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#666666"))
        }
    }
}
