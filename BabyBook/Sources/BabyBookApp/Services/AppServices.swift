import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Security

// MARK: - Keychain 服务
/// 基于 iOS Security 框架的 Keychain 封装
/// 用于安全存储 device_id 等敏感标识信息，App 卸载后数据仍然保留
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidStatus(OSStatus)
    case conversionFailed
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.babybook.app"

    /// 保存字符串到 Keychain
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.conversionFailed
        }

        // 先尝试删除已存在的项
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.invalidStatus(status)
        }
    }

    /// 从 Keychain 读取字符串
    func read(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.invalidStatus(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.conversionFailed
        }

        return value
    }

    /// 从 Keychain 删除项
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.invalidStatus(status)
        }
    }
}

// MARK: - 设备标识服务
class DeviceService {
    static let shared = DeviceService()

    private let deviceIdKey = "com.babybook.deviceId"

    /// 获取设备唯一标识
    /// 首次启动时生成，存入 iOS Keychain，卸载后重新安装不会丢失
    var deviceId: String {
        // 1. 优先从 Keychain 读取（生产环境）
        if let keychainId = try? KeychainService.shared.read(key: deviceIdKey) {
            return keychainId
        }

        // 2. 尝试从 UserDefaults 迁移（兼容旧版本）
        if let legacyId = UserDefaults.standard.string(forKey: deviceIdKey) {
            // 迁移到 Keychain
            try? KeychainService.shared.save(key: deviceIdKey, value: legacyId)
            // 清除 UserDefaults 中的旧数据
            UserDefaults.standard.removeObject(forKey: deviceIdKey)
            return legacyId
        }

        // 3. 生成新的 deviceId
        let newId = "device_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))"
        try? KeychainService.shared.save(key: deviceIdKey, value: newId)
        return newId
    }

    /// 重置设备标识（调试用）
    func resetDeviceId() {
        try? KeychainService.shared.delete(key: deviceIdKey)
        UserDefaults.standard.removeObject(forKey: deviceIdKey)
    }
}

// MARK: - 订单状态管理
class OrderStatusManager: ObservableObject {
    static let shared = OrderStatusManager()

    @Published var currentOrder: BackendOrder?
    @Published var currentTask: BackendTask?
    @Published var isPolling = false
    @Published var isTimeout = false  // 新增：超时标志
    @Published var pollingFailureCount = 0  // 新增：连续轮询失败次数

    private var pollingTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?  // 新增：超时计时器
    private let pollingInterval: UInt64 = 3_000_000_000 // 3 秒（纳秒）
    private let maxPollingDuration: UInt64 = 300_000_000_000 // 5 分钟（纳秒）
    private let maxPollingFailureCount = 3  // 新增：连续失败阈值

    // MARK: - 本地持久化
    private let orderKey = "com.babybook.lastOrder"
    private let orderStatusKey = "com.babybook.lastOrderStatus"
    private let orderSavedAtKey = "com.babybook.lastOrderSavedAt"
    /// 本地订单最长有效期：30 分钟（AI 生成最长约 10 分钟，留充足余量）
    /// 超过此时间的本地记录视为过期，自动清除，避免历史失败记录反复弹窗
    private let orderMaxAge: TimeInterval = 30 * 60

    /// 保存当前订单到本地（用于崩溃/杀后台后恢复）
    func saveCurrentOrder(_ order: BackendOrder) {
        if let data = try? JSONEncoder().encode(order) {
            UserDefaults.standard.set(data, forKey: orderKey)
            UserDefaults.standard.set(order.status, forKey: orderStatusKey)
            // 记录保存时间，用于过期检查
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: orderSavedAtKey)
        }
    }

    /// 加载本地保存的订单（超过 30 分钟的记录自动清除）
    func loadLastOrder() -> BackendOrder? {
        guard let data = UserDefaults.standard.data(forKey: orderKey) else { return nil }
        guard let order = try? JSONDecoder().decode(BackendOrder.self, from: data) else { return nil }

        // 1. 优先用保存时间戳判断是否过期
        let savedAt = UserDefaults.standard.double(forKey: orderSavedAtKey)
        if savedAt > 0 {
            let age = Date().timeIntervalSince1970 - savedAt
            if age > orderMaxAge {
                print("[订单恢复] 本地订单已过期（保存于\(Int(age/60))分钟前），自动清除")
                clearSavedOrder()
                return nil
            }
            return order
        }

        // 2. 旧版本没有时间戳，用订单的 createdAt 字段兜底
        let formatter = ISO8601DateFormatter()
        if let createdDate = formatter.date(from: order.createdAt) {
            let age = Date().timeIntervalSince(createdDate)
            if age > orderMaxAge {
                print("[订单恢复] 本地订单已过期（创建于\(Int(age/60))分钟前），自动清除")
                clearSavedOrder()
                return nil
            }
        }

        return order
    }

    /// 加载待验证的订单 ID（用于交易恢复）
    func loadPendingOrderId() -> String? {
        guard let order = loadLastOrder() else { return nil }
        // 只有 UNPAID 或 GENERATING 状态的订单才需要恢复
        if order.status == "UNPAID" || order.status == "GENERATING" || order.status == "PAID" {
            return order.id
        }
        return nil
    }

    /// 清除本地保存的订单
    func clearSavedOrder() {
        UserDefaults.standard.removeObject(forKey: orderKey)
        UserDefaults.standard.removeObject(forKey: orderStatusKey)
        UserDefaults.standard.removeObject(forKey: orderSavedAtKey)
    }

    /// 恢复订单：App 启动或回到前台时调用，检查是否有未完成的订单
    /// 注意：此函数只负责「查询+返回订单」，不在这里启动轮询。
    /// 轮询由 GeneratingView.onAppear 统一调用 startPolling，避免弹窗等待期间
    /// 后台 timeoutTask 提前启动、与 GeneratingView 产生竞态（旧 timeoutTask 的
    /// isTimeout=true 可能在新监听器建立后才被 emit，误触发失败页跳转）。
    func restoreOrderIfNeeded() async -> BackendOrder? {
        guard let localOrder = loadLastOrder() else { return nil }

        do {
            // 从后端获取最新订单状态
            let latestOrder = try await NetworkService.shared.getOrder(orderId: localOrder.id)

            await MainActor.run {
                self.currentOrder = latestOrder
            }

            // 根据状态决定是否需要恢复（不在此处 startPolling，由 GeneratingView 统一负责）
            switch latestOrder.status {
            case "PAID":
                return latestOrder
            case "GENERATING":
                return latestOrder
            case "FAILED":
                return latestOrder
            case "UNPAID":
                // 如果后端仍是 UNPAID，但本地已经走到 PAID/GENERATING/FAILED，
                // 说明可能是后端状态同步延迟，优先信任本地状态，确保杀端后能恢复。
                if localOrder.status == "PAID" || localOrder.status == "GENERATING" || localOrder.status == "FAILED" {
                    await MainActor.run {
                        self.currentOrder = localOrder
                    }
                    return localOrder
                }
                return nil
            case "SUCCESS":
                return latestOrder
            case "CANCELLED":
                clearSavedOrder()
                return nil
            default:
                return nil
            }
        } catch {
            print("恢复订单网络请求失败，尝试使用本地订单: \(error)")
            // 网络异常时回退到本地保存的订单，只要尚未完成就允许恢复（不 startPolling）
            switch localOrder.status {
            case "PAID", "GENERATING", "UNPAID", "FAILED", "SUCCESS":
                await MainActor.run {
                    self.currentOrder = localOrder
                }
                return localOrder
            default:
                clearSavedOrder()
                return nil
            }
        }
    }

    /// 开始轮询任务状态
    func startPolling(orderId: String) {
        stopPolling()
        isPolling = true
        isTimeout = false
        pollingFailureCount = 0
        // 清空旧 task，避免新的监听器/立即检查读到上次遗留的 FAILED/COMPLETED 状态
        currentTask = nil

        // 保存当前订单到本地（用于崩溃恢复）
        if let order = currentOrder {
            saveCurrentOrder(order)
        }

        // 启动超时计时器（5分钟）
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: maxPollingDuration)
            await MainActor.run {
                if self.isPolling {
                    self.isTimeout = true
                    self.isPolling = false
                    self.pollingTask?.cancel()
                }
            }
        }

        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    if let task = try await NetworkService.shared.getTaskByOrderId(orderId: orderId) {
                        await MainActor.run {
                            self.currentTask = task
                            self.pollingFailureCount = 0
                        }

                        // 任务完成或失败，停止轮询
                        if task.status == "COMPLETED" || task.status == "FAILED" || task.status == "CANCELLED" {
                            await MainActor.run {
                                self.isPolling = false
                            }
                            break
                        }
                    } else {
                        // 任务尚未创建（404），属于正常等待阶段，不计入网络失败
                        await MainActor.run {
                            self.pollingFailureCount = 0
                        }
                    }
                } catch {
                    print("轮询任务状态失败: \(error.localizedDescription)")
                    // 只有真正的网络错误才累计失败次数，业务错误（5xx等）不视为本地断网
                    if shouldTreatAsNetworkFailure(error) {
                        await MainActor.run {
                            self.pollingFailureCount += 1
                        }
                    } else {
                        await MainActor.run {
                            self.pollingFailureCount = 0
                        }
                    }
                }

                // 等待 3 秒后再次轮询
                try? await Task.sleep(nanoseconds: pollingInterval)
            }
        }
    }

    /// 判断错误是否应被视为网络异常（用于弹网络 Toast）
    private func shouldTreatAsNetworkFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        // NSURLError 网络相关错误码
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorCallIsActive,
                 NSURLErrorDataNotAllowed:
                return true
            default:
                return false
            }
        }
        // 自定义网络错误
        if let apiError = error as? APIError, case .networkError = apiError {
            return true
        }
        return false
    }

    /// 停止轮询
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        timeoutTask?.cancel()
        timeoutTask = nil
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
