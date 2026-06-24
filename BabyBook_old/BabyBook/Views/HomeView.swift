import SwiftUI

// MARK: - 首页
struct HomeView: View {
    @State private var selectedBook: Book? = nil
    @State private var showDetail = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    bannerSection
                    bookListSection
                    Spacer().frame(height: 40)
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            BookDetailView(book: book)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("宝贝绘本")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))

                Text("AI 定制专属绘本")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()
        }
    }

    // MARK: - Banner
    private var bannerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#F28C28").opacity(0.15),
                            Color(hex: "#F6D7A7").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .padding(.horizontal, 24)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("上传 1 张照片")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text("1 分钟生成宝宝专属绘本")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F28C28"))
                        Text("AI 智能生成")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#F28C28"))
                    }
                }
                .padding(.leading, 40)

                Spacer()

                // 装饰插图
                ZStack {
                    Circle()
                        .fill(Color(hex: "#F28C28").opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "#F28C28"))
                }
                .padding(.trailing, 40)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
    }

    // MARK: - 绘本列表
    private var bookListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("精选绘本")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))
                .padding(.horizontal, 24)
                .padding(.top, 24)

            ForEach(MockService.shared.mockBooks) { book in
                BookCard(book: book)
                    .onTapGesture {
                        selectedBook = book
                    }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - 绘本卡片
struct BookCard: View {
    let book: Book

    var body: some View {
        HStack(spacing: 16) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#FFF5E6"))
                    .frame(width: 100, height: 130)

                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#F28C28").opacity(0.3))
            }

            // 信息
            VStack(alignment: .leading, spacing: 6) {
                Text(book.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                Text("\(book.pageCount)页 · 中英双语")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#F28C28"))
                    Text("4.9")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#F28C28"))
                }

                Spacer()

                HStack {
                    Text("¥\(String(format: "%.2f", book.price))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#F28C28"))

                    Spacer()

                    Text("一键定制")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#F28C28"))
                        .cornerRadius(12)
                }
            }
            .padding(.vertical, 12)

            Spacer()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
