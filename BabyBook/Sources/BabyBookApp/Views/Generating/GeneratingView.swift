import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

// MARK: - 生成中页面（接入真实任务轮询）
struct GeneratingView: View {
    let book: Book
    let order: BackendOrder

    @StateObject private var statusManager = OrderStatusManager.shared
    @State private var navigateToComplete = false
    @State private var navigateToFailureResult = false
    @State private var statusText = "绘本创作中..."
    @State private var remainingSeconds = 60
    @State private var timer: Timer?
    @State private var showToast = false
    @State private var toastMessage: String? = nil
    @State private var failureErrorMessage: String? = nil
    @State private var downloadTask: Task<Void, Never>?
    @State private var isFinalizing = false
    @State private var finalizingProgress = 0
    @State private var finalizingTimer: Timer?
    @State private var isDownloadPaused = false
    @State private var isWaitingRetry = false          // 是否处于重试等待中
    @State private var isVerifyingFailure = false       // 是否正在核实失败（查订单状态，防重复触发）
    @State private var failureVerifyTask: Task<Void, Never>?  // 核实失败状态的任务句柄，用于页面消失时取消
    @State private var networkRecoveredContinuation: CheckedContinuation<Void, Never>?  // 网络恢复时打断等待
    @State private var networkMonitor: NWPathMonitor?
    @State private var networkMonitorQueue: DispatchQueue?
    #if canImport(UIKit)
    @State private var preloadedImage: UIImage? = nil
    #endif
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
            }

            // 网络异常底部 Toast
            networkToast
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
            #if canImport(UIKit)
            CompleteView(book: book, order: order, task: statusManager.currentTask, preloadedImage: preloadedImage)
            #else
            CompleteView(book: book, order: order, task: statusManager.currentTask, preloadedImage: nil)
            #endif
        }
        .navigationDestination(isPresented: $navigateToFailureResult) {
            FailureResultView(book: book, order: order.updatingStatus(to: "FAILED"), taskErrorMessage: failureErrorMessage)
        }
        .onAppear {
            persistOrderAsGenerating()
            startGeneration()
        }
        .onDisappear {
            timer?.invalidate()
            finalizingTimer?.invalidate()
            statusManager.stopPolling()
            downloadTask?.cancel()
            failureVerifyTask?.cancel()
            isVerifyingFailure = false
            // 释放可能挂起的重试等待，避免 continuation 泄漏
            networkRecoveredContinuation?.resume()
            networkRecoveredContinuation = nil
            stopNetworkMonitoring()
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

            // 提示文案
            subtitleText
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#666666"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
    }

    // 副标题文案：高亮品牌色加粗
    private var subtitleText: Text {
        let base = Text("预计需要")
            .foregroundColor(Color(hex: "#666666"))
        let highlight1 = Text("1-5分钟")
            .foregroundColor(Color(hex: "#F28C28"))
            .font(.system(size: 14, weight: .bold))
        let middle = Text("即可获得专属绘本\n请不要")
            .foregroundColor(Color(hex: "#666666"))
        let highlight2 = Text("熄屏/关闭页面")
            .foregroundColor(Color(hex: "#F28C28"))
            .font(.system(size: 14, weight: .bold))
        let trailing = Text("，避免生成中断～")
            .foregroundColor(Color(hex: "#666666"))

        return base + highlight1 + middle + highlight2 + trailing
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

    // MARK: - 网络异常底部 Toast
    private var networkToast: some View {
        VStack {
            Spacer()
            if showToast, let message = toastMessage {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(999)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
    }

    // MARK: - 显示 Toast
    private func showNetworkToast(_ message: String) {
        toastMessage = message
        showToast = true
    }

    // MARK: - 隐藏 Toast
    private func hideNetworkToast() {
        showToast = false
    }

    // 计算进度值
    private var progressValue: Double {
        // 绘本已生成完成，准备进入完成页，立刻显示 100%
        if navigateToComplete {
            return 1.0
        }
        if isFinalizing {
            // 整理阶段：finalizingProgress 0→100 线性映射到 80%→100%
            // 下载进行中定时器最多走到 99，下载成功后再平滑补到 100
            return 0.8 + Double(finalizingProgress) / 100.0 * 0.2
        }
        if let task = statusManager.currentTask {
            return min(0.8, Double(task.progress) / 100.0)
        }
        return 0.0
    }

    // MARK: - 启动整理阶段进度动画（从当前进度继续匀速走到 99%）
    private func startFinalizingProgressAnimation() {
        finalizingTimer?.invalidate()

        // 整理阶段预计最多 30 秒，从当前进度匀速走到 99%
        let totalDuration: TimeInterval = 30
        let interval: TimeInterval = 0.5
        let stepCount = Int(totalDuration / interval)
        let stepValue = 100 / Double(stepCount)

        finalizingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // 只在下载进行中才推进进度；暂停或已完成时不动
            guard !self.isDownloadPaused, !self.navigateToComplete else { return }
            if self.finalizingProgress < 99 {
                self.finalizingProgress = min(99, self.finalizingProgress + Int(stepValue))
            }
        }
    }

    // MARK: - 暂停整理阶段进度动画（进度停在当前位置）
    private func pauseFinalizingProgressAnimation() {
        isDownloadPaused = true
    }

    // MARK: - 恢复整理阶段进度动画（从当前进度继续）
    private func resumeFinalizingProgressAnimation() {
        isDownloadPaused = false
    }

    // MARK: - 停止整理阶段进度动画
    private func stopFinalizingProgressAnimation() {
        finalizingTimer?.invalidate()
        finalizingTimer = nil
    }

    // MARK: - 进入生成页时持久化订单为 GENERATING
    private func persistOrderAsGenerating() {
        let generatingOrder = order.updatingStatus(to: "GENERATING")
        OrderStatusManager.shared.currentOrder = generatingOrder
        OrderStatusManager.shared.saveCurrentOrder(generatingOrder)
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
        }
        #else
        // 真机环境：开始轮询任务状态
        statusManager.startPolling(orderId: order.id)
        #if canImport(Network)
        startNetworkMonitoring()
        #endif

        // 监听任务状态变化
        Task {
            for await _ in statusManager.$currentTask.values {
                await MainActor.run {
                    checkTaskStatus()
                }
            }
        }

        // 监听轮询失败次数变化，用于网络异常 Toast
        Task {
            for await _ in statusManager.$pollingFailureCount.values {
                await MainActor.run {
                    updateNetworkToast()
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

    // MARK: - 网络异常 Toast 更新
    private func updateNetworkToast() {
        guard !isFinalizing else {
            hideNetworkToast()
            return
        }

        guard statusManager.isPolling else {
            hideNetworkToast()
            return
        }

        if statusManager.pollingFailureCount >= 3 {
            showNetworkToast("网络连接异常，请检查网络后重试")
        } else if statusManager.pollingFailureCount > 0 {
            showNetworkToast("网络开小差了，正在重试…")
        } else {
            hideNetworkToast()
        }
    }

    #if canImport(Network)
    // MARK: - 监听网络恢复：隐藏 Toast，并在整理阶段立刻打断重试等待
    // 注意：真机后端为局域网 IP，NWPathMonitor 只能判断"有没有网络接口"，
    // 不能保证一定能连上后端。因此这里仅用它作为"尽早重试"的触发信号，
    // 真正能否成功仍由下载结果决定。
    private func startNetworkMonitoring() {
        guard networkMonitor == nil else { return }
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.babybook.networkmonitor")
        monitor.pathUpdateHandler = { path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in
                self.hideNetworkToast()
                // 整理阶段若正处于重试等待中，立刻打断等待，尽早发起下载
                if self.isWaitingRetry {
                    self.resumeRetryWaitImmediately()
                }
            }
        }
        monitor.start(queue: queue)
        networkMonitor = monitor
        networkMonitorQueue = queue
    }

    // MARK: - 立刻结束当前重试等待（网络恢复时调用）
    private func resumeRetryWaitImmediately() {
        networkRecoveredContinuation?.resume()
        networkRecoveredContinuation = nil
    }

    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        networkMonitorQueue = nil
    }
    #endif

    private func handleTimeout() {
        timer?.invalidate()
        statusManager.stopPolling()
        showToast = false
        failureErrorMessage = "生成超时，请检查网络后重试"
        navigateToFailureResult = true
    }

    private func checkTaskStatus() {
        guard let task = statusManager.currentTask else { return }

        switch task.status {
        case "COMPLETED":
            guard !isFinalizing else { return }
            statusText = "创作完成 正在呈现…"
            timer?.invalidate()
            statusManager.stopPolling()
            hideNetworkToast()
            resetPollingFailureState()
            isFinalizing = true
            finalizingProgress = 0
            isDownloadPaused = false
            startFinalizingProgressAnimation()
            // 生成完成，自动保存绘本到本地并预加载
            downloadTask = Task {
                await processCompletedTask()
            }
        case "FAILED":
            // 任务失败不代表最终失败：后端会对失败任务自动重试最多 2 次，
            // 此时任务(task)是 FAILED，但订单(order)仍保持 GENERATING。
            // 因此必须以订单状态为准：订单已 FAILED 才是真正的最终失败，
            // 否则说明后端还在自动重试，应继续留在生成中页轮询等待。
            handleTaskFailed(task: task)
        case "RUNNING":
            statusText = "绘本创作中..."
        case "PENDING":
            statusText = "排队中，即将开始..."
        default:
            break
        }
    }

    // MARK: - 任务失败处理：核实订单状态，区分「最终失败」与「等待自动重试」
    /// 后端失败任务会自动重试最多 2 次：任务(task)=FAILED 期间，订单(order)仍可能是 GENERATING。
    /// 因此收到 task=FAILED 时先查一次订单状态：
    /// - 订单已 FAILED → 真正的最终失败，跳失败结果页
    /// - 订单仍 GENERATING → 后端还在重试，留在生成中页继续轮询等待
    /// - 查询失败（如断网）→ 保守起见继续轮询，不误跳失败页
    private func handleTaskFailed(task: BackendTask) {
        // 防止轮询期间 task 持续为 FAILED 反复触发
        guard !isVerifyingFailure else { return }
        isVerifyingFailure = true

        failureVerifyTask = Task {
            guard !Task.isCancelled else { return }
            let orderStatus: String
            do {
                let latestOrder = try await NetworkService.shared.getOrder(orderId: order.id)
                orderStatus = latestOrder.status
            } catch {
                print("核实订单状态失败，继续轮询等待重试: \(error)")
                // 网络异常查不到订单：不跳失败页，稍后恢复轮询等待后续状态
                await resumePollingAfterRetryDelay()
                return
            }

            await MainActor.run {
                if orderStatus == "FAILED" {
                    // 订单确认最终失败，跳失败结果页
                    statusText = "生成失败"
                    timer?.invalidate()
                    statusManager.stopPolling()
                    hideNetworkToast()
                    failureErrorMessage = task.errorMessage
                    navigateToFailureResult = true
                }
            }

            if orderStatus != "FAILED" {
                // 订单仍在生成中（后端每 2 分钟自动重试一次），留在本页，
                // 延迟后恢复轮询等待，避免任务仍为 FAILED 时高频重复请求
                await MainActor.run { statusText = "正在重新生成..." }
                await resumePollingAfterRetryDelay()
            }
        }
    }

    // MARK: - 延迟后恢复轮询（用于任务失败但订单仍在自动重试的等待）
    /// 后端失败任务重试间隔为 2 分钟，前端用较短延迟定期复查，
    /// 既能较快感知重试结果，又不会在中间态高频打请求。
    private func resumePollingAfterRetryDelay() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 秒
        guard !Task.isCancelled else { return }
        await MainActor.run {
            isVerifyingFailure = false
            if !statusManager.isPolling {
                statusManager.startPolling(orderId: order.id)
            }
        }
    }

    // MARK: - 清除轮询阶段的网络异常提示状态
    private func resetPollingFailureState() {
        statusManager.pollingFailureCount = 0
        statusManager.isTimeout = false
    }

    // MARK: - 生成完成后处理：下载、保存、预加载、跳转
    private func processCompletedTask() async {
        guard !Task.isCancelled else { return }
        guard let task = statusManager.currentTask,
              let resultUrl = task.resultUrl else {
            await MainActor.run {
                failureErrorMessage = "任务结果为空"
                navigateToFailureResult = true
            }
            return
        }

        await MainActor.run {
            statusText = "创作完成 正在呈现…"
        }

        do {
            let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)
            guard !Task.isCancelled else { return }

            try writeGeneratedBook(imageData: imageData, createTime: parseISODate(task.updatedAt))

            #if canImport(UIKit)
            let preloaded = UIImage(data: imageData)
            #else
            let preloaded: UIImage? = nil
            #endif

            stopFinalizingProgressAnimation()
            OrderStatusManager.shared.clearSavedOrder()
            await navigateToCompleteWithMinDelay(preloadedImage: preloaded)
        } catch {
            guard !Task.isCancelled else { return }
            print("下载或预加载图片失败: \(error)")
            await MainActor.run {
                // 下载失败：暂停进度，进度停在当前位置
                pauseFinalizingProgressAnimation()
                statusText = "创作完成 正在呈现…"
                showNetworkToast("网络开小差了，正在重试...")
            }
            await retryDownloadAndPreload(error: error)
        }
    }

    // MARK: - 更新整理阶段进度（带动画）
    private func updateFinalizingProgress(target: Int) async {
        await MainActor.run {
            finalizingProgress = target
        }
        // 给 UI 动画留出时间
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    // MARK: - 下载/预加载失败重试
    private func retryDownloadAndPreload(error: Error, currentAttempt: Int = 1) async {
        guard !Task.isCancelled else { return }

        let retryIntervals: [UInt64] = [
            2_000_000_000,
            4_000_000_000,
            6_000_000_000,
            8_000_000_000,
            10_000_000_000
        ]

        // 显示重试提示，等待期间进度保持暂停
        await MainActor.run {
            statusText = "创作完成 正在呈现…"
            showNetworkToast("网络开小差了，正在重试...")
        }

        // 等待递增间隔（若期间网络恢复，会被立刻打断，尽早重试）
        let interval = retryIntervals[min(currentAttempt - 1, retryIntervals.count - 1)]
        await waitForRetry(nanoseconds: interval)

        guard !Task.isCancelled else { return }

        guard let task = statusManager.currentTask,
              let resultUrl = task.resultUrl else {
            await MainActor.run {
                failureErrorMessage = "任务结果为空"
                navigateToFailureResult = true
                hideNetworkToast()
            }
            return
        }

        do {
            let imageData = try await NetworkService.shared.downloadFile(from: resultUrl)
            guard !Task.isCancelled else { return }

            // 下载成功：恢复进度并平滑走到完成
            await MainActor.run {
                resumeFinalizingProgressAnimation()
                hideNetworkToast()
            }

            try writeGeneratedBook(imageData: imageData, createTime: parseISODate(task.updatedAt))

            #if canImport(UIKit)
            let preloaded = UIImage(data: imageData)
            #else
            let preloaded: UIImage? = nil
            #endif

            OrderStatusManager.shared.clearSavedOrder()
            await navigateToCompleteWithMinDelay(preloadedImage: preloaded)
        } catch {
            guard !Task.isCancelled else { return }
            print("第 \(currentAttempt) 次重试失败: \(error)")
            // 仍然失败：保持暂停，继续下一轮重试
            await MainActor.run {
                pauseFinalizingProgressAnimation()
            }
            await retryDownloadAndPreload(error: error, currentAttempt: currentAttempt + 1)
        }
    }

    // MARK: - 可被网络恢复打断的重试等待
    /// 正常情况下等待 nanoseconds；若期间 NWPathMonitor 检测到网络恢复，则立刻返回。
    /// 两个恢复来源（定时到期 / 网络恢复）通过 MainActor 串行 + continuation 判空，确保只恢复一次。
    private func waitForRetry(nanoseconds: UInt64) async {
        await MainActor.run { isWaitingRetry = true }

        // 定时到期任务：到点后若 continuation 仍在，则由它恢复
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: nanoseconds)
            if let c = self.networkRecoveredContinuation {
                self.networkRecoveredContinuation = nil
                c.resume()
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                // 保存 continuation，供 monitor（网络恢复）或 timeoutTask（定时到期）恢复
                self.networkRecoveredContinuation = continuation
            }
        }

        timeoutTask.cancel()
        await MainActor.run { isWaitingRetry = false }
    }

    // MARK: - 跳转完成页前的最小延迟等待
    private func navigateToCompleteWithMinDelay(preloadedImage: UIImage?) async {
        guard !Task.isCancelled else { return }

        let startTime = Date()
        let minDisplayDuration: TimeInterval = 0.8

        // 优先使用已预加载图片，否则尝试从本地文件加载
        var loadedImage = preloadedImage
        if loadedImage == nil {
            loadedImage = await loadImageFromLocalFile()
        }

        // 停止匀速定时器，改为平滑地从当前进度补到 100%
        stopFinalizingProgressAnimation()
        await smoothFinishProgressToFull()

        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, minDisplayDuration - elapsed)

        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        guard !Task.isCancelled else { return }

        await MainActor.run {
            statusText = "生成完成！"
            #if canImport(UIKit)
            self.preloadedImage = loadedImage
            #endif
            self.navigateToComplete = true
        }
    }

    // MARK: - 平滑地把进度从当前值补到 100%
    private func smoothFinishProgressToFull() async {
        // 从当前进度匀速走到 100，总时长约 0.5 秒，避免瞬间跳变
        let stepInterval: UInt64 = 30_000_000  // 30ms 一步
        while finalizingProgress < 100 {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                finalizingProgress = min(100, finalizingProgress + 3)
            }
            try? await Task.sleep(nanoseconds: stepInterval)
        }
    }

    // MARK: - 从本地文件加载图片
    private func loadImageFromLocalFile() async -> UIImage? {
        guard let bookRecord = LocalBookStore.shared.get(orderId: order.id) else { return nil }
        #if canImport(UIKit)
        return UIImage(contentsOfFile: bookRecord.filePath)
        #else
        return nil
        #endif
    }

    // MARK: - 模拟器环境：生成模拟绘本到本地
    private func saveSimulatedGeneratedBook() async {
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
            OrderStatusManager.shared.clearSavedOrder()
            isFinalizing = true
            finalizingProgress = 0
            await navigateToCompleteWithMinDelay(preloadedImage: uiImage)
            print("模拟器自动生成绘本保存成功")
        } catch {
            print("模拟器保存绘本失败: \(error)")
            await MainActor.run {
                failureErrorMessage = "模拟器保存绘本失败"
                navigateToFailureResult = true
            }
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
