import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 我的绘本页（接入本地文件管理）
struct MyBooksView: View {
    @State private var localBooks: [LocalBookMetadata] = []
    @State private var showDeleteAlert = false
    @State private var bookToDelete: LocalBookMetadata?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var selectedBook: LocalBookMetadata?
    @State private var navigateToDetail = false
    @Environment(\.dismiss) private var dismiss

    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 页面标题区域（非空状态时才显示计数）
                if !localBooks.isEmpty {
                    headerSection
                }

                if localBooks.isEmpty {
                    // 空状态
                    emptyState
                } else {
                    // 绘本列表
                    bookList
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#222222"))
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text("我的绘本")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    restorePurchases()
                }) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("恢复购买")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#F28C28"))
                    }
                }
                .disabled(isRestoring)
            }
        }
        #endif
        .onAppear { loadLocalBooks() }
        .alert("删除绘本", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let book = bookToDelete {
                    deleteBook(book)
                }
            }
        } message: {
            Text("确定要删除这本绘本吗？删除后将无法恢复。")
        }
        .alert("恢复购买", isPresented: $showRestoreAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .sheet(isPresented: $showShareSheet) {
            #if canImport(UIKit)
            ShareSheet(items: shareItems)
            #endif
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let book = selectedBook {
                LocalBookDetailView(book: book)
            }
        }
    }

    // MARK: - Header（非空状态显示计数）
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !localBooks.isEmpty {
                Text("共 \(localBooks.count) 本")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            // 空状态插图
            ZStack {
                Circle()
                    .fill(Color(hex: "#F6D7A7").opacity(0.3))
                    .frame(width: 120, height: 120)

                Image(systemName: "books.vertical")
                    .font(.system(size: 56))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.4))
            }

            Text("还没有绘本")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            Text("定制绘本后，PDF文件将保存在这里\n您可以随时查看、分享和管理")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#666666"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: { dismiss() }) {
                Text("去定制绘本")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#F28C28"))
                    .cornerRadius(24)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 绘本列表
    private var bookList: some View {
        List {
            ForEach(localBooks) { book in
                Button(action: {
                    selectedBook = book
                    navigateToDetail = true
                }) {
                    LocalBookRow(book: book)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        bookToDelete = book
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }

                    Button {
                        shareBook(book)
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .tint(Color(hex: "#F28C28"))
                }
                .listRowBackground(Color(hex: "#FFF9F2"))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: 8,
                    leading: 24,
                    bottom: 8,
                    trailing: 24
                ))
            }
        }
        .listStyle(.plain)
        .background(Color(hex: "#FFF9F2"))
    }

    // MARK: - 加载本地绘本
    private func loadLocalBooks() {
        localBooks = LocalBookStore.shared.loadAll()
            .sorted { $0.createTime > $1.createTime }
    }

    // MARK: - 删除绘本
    private func deleteBook(_ book: LocalBookMetadata) {
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
        loadLocalBooks()
    }

    // MARK: - 分享绘本
    private func shareBook(_ book: LocalBookMetadata) {
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

    // MARK: - 恢复购买
    private func restorePurchases() {
        isRestoring = true

        Task {
            do {
                try await PaymentService.shared.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                    restoreMessage = "购买恢复成功！已购买的绘本将自动显示。"
                    showRestoreAlert = true
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    restoreMessage = "恢复购买失败：\(error.localizedDescription)"
                    showRestoreAlert = true
                }
            }
        }
    }

    // MARK: - 返回首页（已改为 dismiss，因为移除了 TabBar）
    private func goToHome() {
        dismiss()
    }
}

#if canImport(UIKit)
// MARK: - 系统分享面板
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - 本地绘本行
struct LocalBookRow: View {
    let book: LocalBookMetadata

    var body: some View {
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
                    .frame(width: 64, height: 80)

                #if canImport(UIKit)
                if let uiImage = loadThumbnail() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#F28C28").opacity(0.5))
                }
                #else
                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.5))
                #endif
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(book.bookName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                Text(formatDate(book.createTime))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))

                if let fileSize = getFileSize() {
                    Text(formatFileSize(fileSize))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                }
            }

            Spacer()

            // 查看按钮
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#CCCCCC"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // 加载封面缩略图
    #if canImport(UIKit)
    private func loadThumbnail() -> UIImage? {
        return UIImage(contentsOfFile: book.filePath)
    }
    #endif

    // 获取文件大小
    private func getFileSize() -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: book.filePath) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
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
}

// MARK: - TabItem 定义
enum TabItem {
    case home
    case myBooks
}

// MARK: - 全局通知
extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MyBooksView()
    }
}
