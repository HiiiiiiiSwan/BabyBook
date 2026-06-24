import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 我的绘本页（接入本地文件管理）
struct MyBooksView: View {
    @State private var localBooks: [LocalBook] = []
    @State private var showDeleteAlert = false
    @State private var bookToDelete: LocalBook?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 页面标题
                headerSection

                if localBooks.isEmpty {
                    // 空状态
                    emptyState
                } else {
                    // 绘本列表
                    bookList
                }
            }
        }
        .navigationTitle("我的绘本")
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
        .sheet(isPresented: $showShareSheet) {
            #if canImport(UIKit)
            ShareSheet(items: shareItems)
            #endif
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("我的绘本")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))
                .padding(.horizontal, 24)
                .padding(.top, 20)

            if !localBooks.isEmpty {
                Text("共 \(localBooks.count) 本")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
                    .padding(.horizontal, 24)
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

            NavigationLink(destination: HomeView()) {
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
                LocalBookRow(book: book)
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
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])

            var books: [LocalBook] = []
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("book_") && (fileName.hasSuffix(".png") || fileName.hasSuffix(".pdf")) {
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    // 从文件名提取 orderId
                    let orderId = fileName
                        .replacingOccurrences(of: "book_", with: "")
                        .replacingOccurrences(of: ".png", with: "")
                        .replacingOccurrences(of: ".pdf", with: "")

                    books.append(LocalBook(
                        id: orderId,
                        orderId: orderId,
                        bookName: "专属绘本 \(books.count + 1)",
                        filePath: file.path,
                        createTime: creationDate,
                        fileSize: fileSize
                    ))
                }
            }

            // 按创建时间倒序排列
            localBooks = books.sorted { $0.createTime > $1.createTime }
        } catch {
            print("加载本地绘本失败: \(error)")
        }
    }

    // MARK: - 删除绘本
    private func deleteBook(_ book: LocalBook) {
        do {
            try FileManager.default.removeItem(atPath: book.filePath)
            loadLocalBooks()
        } catch {
            print("删除绘本失败: \(error)")
        }
    }

    // MARK: - 分享绘本
    private func shareBook(_ book: LocalBook) {
        let fileURL = URL(fileURLWithPath: book.filePath)
        shareItems = [fileURL]
        showShareSheet = true
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
    let book: LocalBook

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

                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.5))
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(book.bookName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                Text(formatDate(book.createTime))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))

                Text(formatFileSize(book.fileSize))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))
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

// MARK: - Preview
#Preview {
    NavigationStack {
        MyBooksView()
    }
}
