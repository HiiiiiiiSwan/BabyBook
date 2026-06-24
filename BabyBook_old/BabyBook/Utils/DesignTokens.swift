import SwiftUI

// MARK: - Design Tokens
// 遵循 style.md 设计规范，禁止硬编码

enum DesignTokens {

    // MARK: Colors
    enum Colors {
        static let primary = Color(hex: "#F28C28")      // Baby Orange - CTA按钮/价格/进度
        static let secondary = Color(hex: "#F6D7A7")     // Warm Cream - 插画辅助色/卡片背景/装饰元素
        static let background = Color(hex: "#FFF9F2")    // App背景
        static let pageBackground = Color(hex: "#FFFDF9") // 页面背景
        static let success = Color(hex: "#8BC34A")       // 成功状态

        static let primaryText = Color(hex: "#222222")   // 主文字
        static let secondaryText = Color(hex: "#666666") // 辅助文字
        static let tertiaryText = Color(hex: "#999999")  // 三级文字

        static let border = Color(hex: "#F0E8DE")        // 边框
        static let divider = Color(hex: "#F5F0E8")       // 分割线

        static let cardBackground = Color.white
        static let secondaryButtonBorder = Color(hex: "#F28C28")
        static let disabledBackground = Color(hex: "#E5E5E5")
        static let disabledText = Color(hex: "#999999")
    }

    // MARK: Typography
    enum Typography {
        static let h1 = Font.system(size: 32, weight: .bold, design: .default)    // 页面主标题
        static let h2 = Font.system(size: 24, weight: .bold, design: .default)     // 模块标题
        static let h3 = Font.system(size: 18, weight: .semibold, design: .default)  // 卡片标题
        static let body = Font.system(size: 16, weight: .medium, design: .default)  // 正文
        static let caption = Font.system(size: 12, weight: .regular, design: .default) // 辅助说明
    }

    // MARK: Spacing (8pt Grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let xxxxl: CGFloat = 64
    }

    // MARK: Radius
    enum Radius {
        static let card: CGFloat = 24
        static let bookCover: CGFloat = 28
        static let button: CGFloat = 999  // 全圆角
        static let modal: CGFloat = 32
    }

    // MARK: Shadows
    enum Shadows {
        static let card = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 30,
            x: 0,
            y: 8
        )
        static let hover = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 40,
            x: 0,
            y: 12
        )
    }

    // MARK: Layout
    enum Layout {
        static let pagePadding: CGFloat = 24
        static let moduleGap: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 56
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
