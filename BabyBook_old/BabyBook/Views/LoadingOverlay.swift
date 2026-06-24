import SwiftUI

// MARK: - 加载遮罩组件
struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color(hex: "#F28C28"))

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#666666"))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 4)
        }
    }
}

#Preview {
    LoadingOverlay(message: "正在上传照片...")
}
