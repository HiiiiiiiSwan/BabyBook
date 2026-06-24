import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 设备标识服务
class DeviceService {
    static let shared = DeviceService()

    private let deviceIdKey = "com.babybook.deviceId"

    /// 获取设备唯一标识
    /// 首次启动时生成，存入 iOS Keychain，卸载后重新安装会生成新的
    var deviceId: String {
        // 先尝试从 UserDefaults 读取（开发阶段使用，生产环境应使用 Keychain）
        if let storedId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return storedId
        }

        // 生成新的 deviceId
        let newId = "device_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))"
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    /// 重置设备标识（调试用）
    func resetDeviceId() {
        UserDefaults.standard.removeObject(forKey: deviceIdKey)
    }
}

// MARK: - 订单状态管理
class OrderStatusManager: ObservableObject {
    static let shared = OrderStatusManager()

    @Published var currentOrder: BackendOrder?
    @Published var currentTask: BackendTask?
    @Published var isPolling = false

    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: UInt64 = 3_000_000_000 // 3 秒（纳秒）

    /// 开始轮询任务状态
    func startPolling(orderId: String) {
        stopPolling()
        isPolling = true

        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    if let task = try await NetworkService.shared.getTaskByOrderId(orderId: orderId) {
                        await MainActor.run {
                            self.currentTask = task
                        }

                        // 任务完成或失败，停止轮询
                        if task.status == "COMPLETED" || task.status == "FAILED" || task.status == "CANCELLED" {
                            await MainActor.run {
                                self.isPolling = false
                            }
                            break
                        }
                    }
                } catch {
                    print("轮询任务状态失败: \(error.localizedDescription)")
                }

                // 等待 3 秒后再次轮询
                try? await Task.sleep(nanoseconds: pollingInterval)
            }
        }
    }

    /// 停止轮询
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }

    /// 取消任务
    func cancelTask() async {
        guard let task = currentTask else { return }
        do {
            try await NetworkService.shared.cancelTask(taskId: task.id)
            stopPolling()
        } catch {
            print("取消任务失败: \(error.localizedDescription)")
        }
    }
}
