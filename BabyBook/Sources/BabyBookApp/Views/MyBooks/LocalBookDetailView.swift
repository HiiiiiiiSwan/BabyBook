import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 绘本详情查看页（从我的绘本页点击进入）
struct LocalBookDetailView: View {
    let book: LocalBookMetadata
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    bookPreviewSection
                    actionButtons
                    weakWarning
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#222222"))
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text(book.bookName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { shareBook() }) {
                        Label("分享绘本", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("删除绘本", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#222222"))
                }
            }
        }
        #endif
        .alert("删除绘本", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("确定要删除这本绘本吗？删除后将无法恢复。")
        }
        .sheet(isPresented: $showShareSheet) {
            #if canImport(UIKit)
            ShareSheet(items: shareItems)
            #endif
        }
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                LoadingOverlay(message: "正在处理...")
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
                Text("宝宝的专属绘本")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F28C28"))
            }
            .padding(.top, 20)

            Text(formatDate(book.createTime))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
    }

    // MARK: - 绘本预览
    private var bookPreviewSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)

                #if canImport(UIKit)
                if let uiImage = loadBookImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    bookPreviewPlaceholder
                }
                #else
                bookPreviewPlaceholder
                #endif
            }
            .frame(width: 240, height: 240)

            Text(book.bookName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            if let fileSize = getFileSize() {
                Text(formatFileSize(fileSize))
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
            }
        }
        .padding(.top, 16)
    }

    private var bookPreviewPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
            Text("绘本预览")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 查看 PDF
            Button(action: { openPDF() }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("查看 PDF 电子版")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#F28C28"))
                .cornerRadius(28)
            }

            // 分享绘本
            Button(action: { shareBook() }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享绘本")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#666666"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                )
            }

            // 获取实体书
            Button(action: { openPhysicalBookStore() }) {
                Text("获取实体书（跳转微店）")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#666666"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                .background(Color.white)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var weakWarning: some View {
        VStack(spacing: 4) {
            Text("绘本已保存在本地")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#999999"))
            Text("卸载 App 后将无法恢复哦~")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#CCCCCC"))
        }
        .padding(.top, 16)
    }

    // MARK: - 加载绘本图片
    #if canImport(UIKit)
    private func loadBookImage() -> UIImage? {
        return UIImage(contentsOfFile: book.filePath)
    }
    #endif

    // MARK: - 获取文件大小
    private func getFileSize() -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: book.filePath) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - 格式化文件大小
    private func formatFileSize(_ size: Int64) -> String {
        let kb = Double(size) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }

    // MARK: - 打开 PDF
    private func openPDF() {
        let pdfPath = book.filePath.replacingOccurrences(of: ".png", with: ".pdf")
        guard FileManager.default.fileExists(atPath: pdfPath) else {
            errorMessage = "PDF 文件不存在，请重新生成"
            showError = true
            return
        }

        #if os(iOS)
        let fileURL = URL(fileURLWithPath: pdfPath)
        shareItems = [fileURL]
        showShareSheet = true
        #endif
    }

    // MARK: - 分享绘本
    private func shareBook() {
        var items: [Any] = []

        // 优先分享 PDF，如果没有则分享图片
        let pdfPath = book.filePath.replacingOccurrences(of: ".png", with: ".pdf")
        if FileManager.default.fileExists(atPath: pdfPath) {
            items.append(URL(fileURLWithPath: pdfPath))
        } else {
            items.append(URL(fileURLWithPath: book.filePath))
        }

        shareItems = items
        showShareSheet = true
    }

    // MARK: - 删除绘本
    private func deleteBook() {
        // 删除图片文件
        if FileManager.default.fileExists(atPath: book.filePath) {
            try? FileManager.default.removeItem(atPath: book.filePath)
        }
        // 删除对应 PDF
        let pdfPath = book.filePath.replacingOccurrences(of: ".png", with: ".pdf")
        if FileManager.default.fileExists(atPath: pdfPath) {
            try? FileManager.default.removeItem(atPath: pdfPath)
        }
        // 删除元数据
        LocalBookStore.shared.delete(orderId: book.orderId)

        // 返回上一页
        dismiss()
    }

    // MARK: - 打开实体书微店
    private func openPhysicalBookStore() {
        let storeURL = URL(string: "https://weidian.com")!
        #if os(iOS)
        UIApplication.shared.open(storeURL)
        #endif
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LocalBookDetailView(
            book: LocalBookMetadata(
                id: "test-order",
                orderId: "test-order",
                bookId: "Book001",
                bookName: "《这是我》",
                filePath: "/tmp/test.png",
                createTime: Date()
            )
        )
    }
}
