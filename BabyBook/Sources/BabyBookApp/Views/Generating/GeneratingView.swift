import SwiftUI

// MARK: - 生成中页面（接入真实任务轮询）
struct GeneratingView: View {
    let book: Book
    let order: BackendOrder

    @StateObject private var statusManager = OrderStatusManager.shared
    @State private var showCancelAlert = false
    @State private var showCannotRefundAlert = false
    @State private var navigateToComplete = false
    @State private var statusText = "魔法生成中..."
    @State private var remainingSeconds = 60
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navPath) private var navPath

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F2").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 中间内容
                contentSection

                Spacer()

                // 底部插画
                bottomIllustration
                    .padding(.bottom, 24)

                // 取消按钮
                Button(action: { showCancelAlert = true }) {
                    Text("取消生成")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#999999"))
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("正在生成专属绘本")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
            }
        }
        .navigationDestination(isPresented: $navigateToComplete) {
            CompleteView(book: book, order: order, task: statusManager.currentTask)
        }
        .onAppear { startGeneration() }
        .onDisappear {
            timer?.invalidate()
            statusManager.stopPolling()
        }
        .alert("取消生成", isPresented: $showCancelAlert) {
            Button("继续生成", role: .cancel) {}
            Button("确认取消", role: .destructive) { cancelGeneration() }
        } message: {
            Text("图片生成费用订单已生成，无法退款，是否确认取消？")
        }
        .alert("提示", isPresented: $showCannotRefundAlert) {
            Button("确定", role: .cancel) {
                goBackToHome()
            }
        } message: {
            Text("绘本生成已取消。由于图片生成服务已调用，订单费用无法退回。")
        }
    }

    private var contentSection: some View {
        VStack(spacing: 24) {
            // 大圆环进度
            ZStack {
                Circle()
                    .stroke(Color(hex: "#F0E8DE"), lineWidth: 10)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(Color(hex: "#F28C28"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progressValue)

                VStack(spacing: 2) {
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(hex: "#F28C28"))
                }
            }
            .frame(height: 200)

            // 状态文字
            Text(statusText)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            if statusManager.isPolling {
                Text("预计剩余 \(remainingSeconds) 秒完成")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
            }

            Text("AI 正在为宝宝打造独一无二的绘本\n请稍候，不要关闭页面哦~")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#999999"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
    }

    private var bottomIllustration: some View {
        #if os(iOS)
        if let uiImage = UIImage(named: "generating") {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            )
        }
        #else
        if let nsImage = NSImage(named: "generating") {
            return AnyView(
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            )
        }
        #endif
        return AnyView(EmptyView())
    }

    // 计算进度值
    private var progressValue: Double {
        if let task = statusManager.currentTask {
            return Double(task.progress) / 100.0
        }
        return 0.0
    }

    private func startGeneration() {
        // 开始倒计时
        remainingSeconds = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
        }

        // 模拟器环境：模拟生成过程，5秒后自动完成并保存绘本
        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            statusText = "生成完成！"
            timer?.invalidate()
            Task {
                await self.saveSimulatedGeneratedBook()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                navigateToComplete = true
            }
        }
        #else
        // 真机环境：开始轮询任务状态
        statusManager.startPolling(orderId: order.id)

        // 监听任务状态变化
        Task {
            for await _ in statusManager.$currentTask.values {
                await MainActor.run {
                    checkTaskStatus()
                }
            }
        }

        // 监听超时状态
        Task {
            for await isTimeout in statusManager.$isTimeout.values {
                if isTimeout {
                    await MainActor.run {
                        handleTimeout()
                    }
                }
            }
        }
        #endif
    }

    private func handleTimeout() {
        timer?.invalidate()
        statusManager.stopPolling()
        errorMessage = "生成超时，请检查网络后重试"
        showError = true
    }

    private func checkTaskStatus() {
        guard let task = statusManager.currentTask else { return }

        switch task.status {
        case "COMPLETED":
            statusText = "生成完成！"
            timer?.invalidate()
            statusManager.stopPolling()
            // 生成完成，自动保存绘本到本地
            Task {
                await saveGeneratedBook()
            }
            // 生成完成，清除本地保存的订单
            OrderStatusManager.shared.clearSavedOrder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                navigateToComplete = true
            }
        case "FAILED":
            statusText = "生成失败"
            timer?.invalidate()
            statusManager.stopPolling()
            errorMessage = task.errorMessage ?? "未知错误"
            showError = true
        case "RUNNING":
            statusText = "正在为宝宝制作专属绘本..."
        case "PENDING":
            statusText = "排队中，即将开始..."
        default:
            break
        }
    }

    @State private var showError = false
    @State private var errorMessage = ""

    private func cancelGeneration() {
        timer?.invalidate()
        Task {
            await statusManager.cancelTask()
            await MainActor.run {
                showCannotRefundAlert = true
            }
        }
    }

    private func goBackToHome() {
        navPath.wrappedValue = NavigationPath()
    }

    // MARK: - 生成完成后自动保存绘本到本地
    private func saveGeneratedBook() async {
        guard let task = statusManager.currentTask,
              let resultUrl = task.resultUrl else {
            print("自动生成绘本保存失败：任务结果为空")
            return
        }

        do {
            let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)
            try writeGeneratedBook(imageData: imageData, createTime: parseISODate(task.updatedAt))
            print("自动生成绘本保存成功")
        } catch {
            print("自动生成绘本保存失败: \(error)")
        }
    }

    // MARK: - 模拟器环境：生成模拟绘本到本地
    private func saveSimulatedGeneratedBook() async {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("模拟器保存绘本失败：无法获取 Documents 目录")
            return
        }

        // 使用 cover 资源生成模拟绘本图片
        #if canImport(UIKit)
        let coverName: String
        switch book.bookId {
        case "Book002":
            coverName = "cover2"
        case "Book003":
            coverName = "cover3"
        default:
            coverName = "cover1"
        }

        guard let uiImage = UIImage(named: coverName) else {
            print("模拟器保存绘本失败：找不到 cover 图片")
            return
        }

        guard let imageData = uiImage.pngData() else {
            print("模拟器保存绘本失败：无法转换图片数据")
            return
        }

        do {
            try writeGeneratedBook(imageData: imageData, createTime: nil)
            print("模拟器自动生成绘本保存成功")
        } catch {
            print("模拟器保存绘本失败: \(error)")
        }
        #endif
    }

    // MARK: - 写入绘本文件和元数据
    private func writeGeneratedBook(imageData: Data, createTime: Date?) throws {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "BabyBook", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取 Documents 目录"])
        }

        let fileName = "book_\(order.id).png"
        let filePath = documentsPath.appendingPathComponent(fileName)
        try imageData.write(to: filePath)

        LocalBookStore.shared.save(
            orderId: order.id,
            bookId: order.bookId,
            bookName: book.name,
            filePath: filePath.path,
            createTime: createTime ?? Date()
        )
    }

    private func parseISODate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GeneratingView(
            book: MockService.shared.mockBooks[0],
            order: BackendOrder(
                id: "test-order-id",
                deviceId: "test-device",
                bookId: "Book001",
                bookName: "《这是我》",
                amount: 3.0,
                status: "GENERATING",
                createdAt: "2026-06-23T10:00:00Z",
                updatedAt: nil
            )
        )
    }
}
