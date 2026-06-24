import SwiftUI

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var showUploadSheet = false
    @State private var currentPageIndex = 0  // 当前展示的页面索引

    var body: some View {
        ZStack {
            Color(hex: "#FAECDD").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    bookPreviewSection
                    bookInfoSection
                    Spacer().frame(height: 180)
                }
            }

            bottomCTA
        }
        .navigationTitle("")
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
        }
        #endif
        .overlay(
            Group {
                if showUploadSheet {
                    UploadSheetView(book: book, isPresented: $showUploadSheet)
                }
            }
        )
    }

    private var bookPreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("绘本示例")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F28C28"))
                    .cornerRadius(12)
                Spacer()
            }
            .padding(.horizontal, 20)

            // 绘本内容展示：使用 TabView 支持左右滑动翻页
            TabView(selection: $currentPageIndex) {
                ForEach(Array(book.pageImages.enumerated()), id: \.offset) { index, pageImage in
                    if let image = loadPageImage(named: pageImage) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .tag(index)
                    } else {
                        // 占位图
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)

                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.square.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "#F28C28").opacity(0.15))
                                Text("\(pageImage)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#999999"))
                            }
                        }
                        .frame(width: 280, height: 280)
                        .tag(index)
                    }
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .frame(height: 320)

            // 分页指示器
            HStack(spacing: 16) {
                Button(action: {
                    if currentPageIndex > 0 {
                        currentPageIndex -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(currentPageIndex > 0 ? Color(hex: "#F28C28") : Color(hex: "#999999"))
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(currentPageIndex == 0)

                Text("第 \(currentPageIndex + 1) / \(book.pageImages.count) 页")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#666666"))

                Button(action: {
                    if currentPageIndex < book.pageImages.count - 1 {
                        currentPageIndex += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(currentPageIndex < book.pageImages.count - 1 ? Color(hex: "#F28C28") : Color(hex: "#999999"))
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(currentPageIndex == book.pageImages.count - 1)
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和页数放在同一行，居中对齐
            HStack(spacing: 8) {
                Text(book.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                Text("\(book.pageCount)页")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#666666"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#F5F0E8"))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            HStack(spacing: 24) {
                InfoItem(icon: "doc.text", title: "\(book.pageCount)页", subtitle: "精美内容")
                InfoItem(icon: "character.book.closed", title: "中英双语", subtitle: "双语启蒙")
                InfoItem(icon: "person.fill", title: "专属定制", subtitle: "宝宝主角")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // 一键定制按钮：样式与首页一致
                ZStack(alignment: .bottom) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showUploadSheet = true
                        }
                    }) {
                        Text("一键定制")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color(hex: "#F28C28"))
                            .cornerRadius(60)
                    }
                    .padding(.horizontal, 32)

                    Text("仅需¥\(String(format: "%.1f", book.price))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E85D5D"))
                        .cornerRadius(12)
                        .offset(x: 80, y: -20)
                }
                .padding(.top, 16)

                // 获取实体书按钮
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("获取实体书")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#666666"))
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
            .background(Color(hex: "#FAECDD"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard)
    }

    // 加载绘本页面图片
    private func loadPageImage(named: String) -> Image? {
        #if os(iOS)
        let folderName = book.templatePath.replacingOccurrences(of: "templates/", with: "")
        let resourcePath = "Resources/\(folderName)"

        // 尝试 folderName 子目录下的 png 文件
        if let path = Bundle.module.path(forResource: named, ofType: "png", inDirectory: resourcePath),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        // 尝试使用 url(forResource:withExtension:subdirectory:) 方式
        if let url = Bundle.module.url(forResource: named, withExtension: "png", subdirectory: resourcePath),
           let uiImage = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: uiImage)
        }
        #else
        let folderName = book.templatePath.replacingOccurrences(of: "templates/", with: "")
        let resourcePath = "Resources/\(folderName)"
        if let path = Bundle.module.path(forResource: named, ofType: "png", inDirectory: resourcePath),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        if let url = Bundle.module.url(forResource: named, withExtension: "png", subdirectory: resourcePath),
           let nsImage = NSImage(contentsOfFile: url.path) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#F28C28"))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#999999"))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        BookDetailView(book: MockService.shared.mockBooks[0])
    }
}
