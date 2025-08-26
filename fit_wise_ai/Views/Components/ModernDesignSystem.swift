//
//  ModernDesignSystem.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  现代化设计系统 - 升级版本
//

import SwiftUI

// MARK: - 现代化AI主题系统 2.0

/// 现代化AI主题配色方案 - 支持深色模式和可访问性
struct ModernAITheme {
    // MARK: - 品牌色系统
    
    /// 主要品牌渐变 - 增强版
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.2, blue: 0.9),    // 深紫蓝
            Color(red: 0.2, green: 0.6, blue: 1.0),    // 亮蓝色  
            Color(red: 0.1, green: 0.8, blue: 0.9)     // 青色
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 次要品牌渐变
    static let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.7, blue: 0.9),
            Color(red: 0.3, green: 0.5, blue: 0.95),
            Color(red: 0.5, green: 0.3, blue: 0.9)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 成功状态渐变
    static let successGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.8, blue: 0.4),
            Color(red: 0.1, green: 0.9, blue: 0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 警告状态渐变
    static let warningGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.6, blue: 0.2),
            Color(red: 1.0, green: 0.7, blue: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 错误状态渐变
    static let errorGradient = LinearGradient(
        colors: [
            Color(red: 0.9, green: 0.3, blue: 0.3),
            Color(red: 1.0, green: 0.4, blue: 0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 背景系统
    
    /// 主背景渐变 - 浅色模式
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 1.0),
            Color(red: 0.94, green: 0.97, blue: 1.0),
            Color(red: 0.90, green: 0.95, blue: 0.98)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// 主背景渐变 - 深色模式
    static let darkBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.03, green: 0.08, blue: 0.18),
            Color(red: 0.02, green: 0.06, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - 语义化颜色
    
    /// 主要强调色
    static let accent = Color(red: 0.3, green: 0.4, blue: 0.95)
    static let accentSecondary = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    /// 状态颜色
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let successLight = Color(red: 0.7, green: 0.95, blue: 0.8)
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let warningLight = Color(red: 1.0, green: 0.95, blue: 0.85)
    static let error = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let errorLight = Color(red: 1.0, green: 0.9, blue: 0.9)
    static let info = Color(red: 0.2, green: 0.7, blue: 1.0)
    static let infoLight = Color(red: 0.9, green: 0.96, blue: 1.0)
    
    /// 文本颜色系统
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let textOnPrimary = Color.white
    static let textOnSecondary = Color.black
    
    /// 表面颜色系统
    static let surface = Color(UIColor.systemBackground)
    static let surfaceElevated = Color(UIColor.secondarySystemBackground)
    static let surfaceElevated2 = Color(UIColor.tertiarySystemBackground)
    static let surfaceOverlay = Color.black.opacity(0.4)
    
    /// 边框和分隔线
    static let border = Color(UIColor.separator)
    static let borderLight = Color(UIColor.separator).opacity(0.5)
    static let divider = Color(UIColor.opaqueSeparator)
    
    // MARK: - 玻璃拟态效果
    
    /// 玻璃背景 - 浅色
    static let glassBackground = Color.white.opacity(0.15)
    static let glassBackgroundStrong = Color.white.opacity(0.25)
    
    /// 玻璃背景 - 深色
    static let glassBackgroundDark = Color.black.opacity(0.15)
    static let glassBackgroundDarkStrong = Color.black.opacity(0.25)
    
    /// 玻璃边框
    static let glassStroke = Color.white.opacity(0.3)
    static let glassStrokeDark = Color.white.opacity(0.1)
    
    // MARK: - 动态颜色支持
    
    /// 自适应玻璃背景
    static let adaptiveGlassBackground = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor.white.withAlphaComponent(0.15)
        default:
            return UIColor.white.withAlphaComponent(0.25)
        }
    })
    
    /// 自适应玻璃边框
    static let adaptiveGlassStroke = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor.white.withAlphaComponent(0.1)
        default:
            return UIColor.white.withAlphaComponent(0.3)
        }
    })
}

// MARK: - 现代化字体系统

struct ModernTypography {
    // 主要字体 - 支持动态字体
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title1 = Font.system(.title, design: .rounded, weight: .bold)
    static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .medium)
    static let body = Font.system(.body, design: .rounded, weight: .regular)
    static let bodyMedium = Font.system(.body, design: .rounded, weight: .medium)
    static let callout = Font.system(.callout, design: .rounded, weight: .medium)
    static let subheadline = Font.system(.subheadline, design: .rounded, weight: .regular)
    static let footnote = Font.system(.footnote, design: .rounded, weight: .regular)
    static let caption = Font.system(.caption, design: .rounded, weight: .regular)
    static let caption2 = Font.system(.caption2, design: .rounded, weight: .regular)
    
    // 特殊用途字体
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .medium, design: .rounded)
    
    // 数字字体 - 等宽
    static let numberLarge = Font.system(.title, design: .monospaced, weight: .semibold)
    static let numberMedium = Font.system(.headline, design: .monospaced, weight: .medium)
    static let numberSmall = Font.system(.callout, design: .monospaced, weight: .regular)
}

// MARK: - 现代化尺寸系统

struct ModernSpacing {
    // 基础间距
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let xxxxl: CGFloat = 40
    
    // 语义化间距
    static let tight: CGFloat = 6
    static let normal: CGFloat = 12
    static let loose: CGFloat = 20
    static let extraLoose: CGFloat = 28
    
    // 特殊用途间距
    static let section: CGFloat = 32  // 区块间距
    static let group: CGFloat = 16    // 组内间距
    static let element: CGFloat = 8   // 元素间距
    static let micro: CGFloat = 4     // 微小间距
}

struct ModernRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    
    // 语义化圆角
    static let button: CGFloat = 12
    static let card: CGFloat = 16
    static let sheet: CGFloat = 20
    static let full: CGFloat = 1000  // 完全圆形
}

struct ModernShadow {
    static let sm = (color: Color.black.opacity(0.04), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    static let md = (color: Color.black.opacity(0.06), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let lg = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    static let xl = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    static let xxl = (color: Color.black.opacity(0.16), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    
    // 特殊阴影
    static let glow = (color: ModernAITheme.accent.opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(0))
    static let success = (color: ModernAITheme.success.opacity(0.2), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    static let error = (color: ModernAITheme.error.opacity(0.2), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
}

// MARK: - 动画系统

struct ModernAnimation {
    // 基础动画时长
    static let fast = 0.2
    static let normal = 0.3
    static let slow = 0.5
    static let verySlow = 0.8
    
    // 缓动函数
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeIn = Animation.easeIn(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    
    // 特殊动画
    static let gentle = Animation.easeOut(duration: slow)
    static let snappy = Animation.easeOut(duration: fast)
    static let elastic = Animation.interpolatingSpring(stiffness: 300, damping: 20)
    
    // 页面转场
    static let pageTransition = Animation.easeInOut(duration: 0.4)
    static let modalPresent = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let modalDismiss = Animation.easeIn(duration: 0.25)
}

// MARK: - 现代化组件尺寸

struct ModernSizes {
    // 按钮高度
    static let buttonSmall: CGFloat = 32
    static let buttonMedium: CGFloat = 44
    static let buttonLarge: CGFloat = 52
    static let buttonExtraLarge: CGFloat = 60
    
    // 图标尺寸
    static let iconXS: CGFloat = 12
    static let iconSM: CGFloat = 16
    static let iconMD: CGFloat = 20
    static let iconLG: CGFloat = 24
    static let iconXL: CGFloat = 32
    static let iconXXL: CGFloat = 40
    
    // 头像尺寸
    static let avatarSM: CGFloat = 32
    static let avatarMD: CGFloat = 40
    static let avatarLG: CGFloat = 56
    static let avatarXL: CGFloat = 80
    
    // 卡片最小高度
    static let cardMinHeight: CGFloat = 60
    static let cardMediumHeight: CGFloat = 120
    static let cardLargeHeight: CGFloat = 200
    
    // 输入框高度
    static let inputHeight: CGFloat = 44
    static let inputHeightLarge: CGFloat = 52
}

// MARK: - 现代化View扩展

extension View {
    /// 应用现代化AI背景
    func modernAIBackground() -> some View {
        self.background(
            ModernAITheme.backgroundGradient
                .ignoresSafeArea(.all)
        )
    }
    
    /// 应用现代化AI深色背景  
    func modernAIDarkBackground() -> some View {
        self.background(
            ModernAITheme.darkBackgroundGradient
                .ignoresSafeArea(.all)
        )
    }
    
    /// 现代化点击效果
    func modernTapEffect(scale: CGFloat = 0.96) -> some View {
        self.scaleEffect(1.0)
            .animation(ModernAnimation.snappy, value: UUID())
    }
    
    /// 现代化阴影
    func modernShadow(_ shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = ModernShadow.md) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 玻璃拟态效果
    func glassEffect(cornerRadius: CGFloat = ModernRadius.lg) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(ModernAITheme.adaptiveGlassBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(ModernAITheme.adaptiveGlassStroke, lineWidth: 1)
                )
        )
    }
    
    /// 现代化卡片样式
    func modernCard(
        cornerRadius: CGFloat = ModernRadius.card,
        shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = ModernShadow.md
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(ModernAITheme.surface)
                .shadow(
                    color: shadow.color,
                    radius: shadow.radius,
                    x: shadow.x,
                    y: shadow.y
                )
        )
    }
}