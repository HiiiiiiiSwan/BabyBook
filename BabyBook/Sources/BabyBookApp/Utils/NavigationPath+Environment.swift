import SwiftUI

// MARK: - 导航路径环境值（用于从任意页面返回首页）
private struct NavPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath> = .constant(NavigationPath())
}

extension EnvironmentValues {
    var navPath: Binding<NavigationPath> {
        get { self[NavPathKey.self] }
        set { self[NavPathKey.self] = newValue }
    }
}
