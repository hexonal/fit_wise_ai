//
//  DesignSystem.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/24.
//

import SwiftUI

// MARK: - 现代AI风格设计系统

/// AI主题配色方案
struct AITheme {
    // 渐变色系
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.2, blue: 0.8),    // 深紫色
            Color(red: 0.2, green: 0.6, blue: 1.0)     // 亮蓝色
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.7, blue: 0.9),    // 青色
            Color(red: 0.3, green: 0.4, blue: 0.9)     // 蓝紫色
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 1.0),  // 淡紫白
            Color(red: 0.95, green: 0.97, blue: 1.0)   // 淡蓝白
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let darkBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),  // 深紫黑
            Color(red: 0.05, green: 0.1, blue: 0.2)     // 深蓝黑
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 单色配色
    static let accent = Color(red: 0.3, green: 0.4, blue: 0.95)
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let error = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    // 中性色
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let surface = Color(UIColor.systemBackground)
    static let surfaceElevated = Color(UIColor.secondarySystemBackground)
    
    // 玻璃磨砂效果
    static let glassBackground = Color.white.opacity(0.1)
    static let glassStroke = Color.white.opacity(0.2)
}

// MARK: - 字体系统
struct AITypography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title1 = Font.system(.title, design: .rounded, weight: .semibold)
    static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .medium)
    static let body = Font.system(.body, design: .rounded, weight: .regular)
    static let callout = Font.system(.callout, design: .rounded, weight: .medium)
    static let caption = Font.system(.caption, design: .rounded, weight: .regular)
}

// MARK: - 尺寸规范
struct AISpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct AIRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - 现代AI卡片组件
struct AICard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let isElevated: Bool
    
    init(
        padding: CGFloat = AISpacing.lg,
        cornerRadius: CGFloat = AIRadius.lg,
        shadowRadius: CGFloat = 10,
        isElevated: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.isElevated = isElevated
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AITheme.surface)
                    .shadow(
                        color: Color.black.opacity(isElevated ? 0.08 : 0),
                        radius: shadowRadius,
                        x: 0,
                        y: isElevated ? 4 : 0
                    )
            )
    }
}

// MARK: - 渐变卡片组件
struct AIGradientCard<Content: View>: View {
    let content: Content
    let gradient: LinearGradient
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        gradient: LinearGradient = AITheme.primaryGradient,
        padding: CGFloat = AISpacing.lg,
        cornerRadius: CGFloat = AIRadius.lg,
        shadowRadius: CGFloat = 15,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.gradient = gradient
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: shadowRadius,
                        x: 0,
                        y: 8
                    )
            )
    }
}

// MARK: - 玻璃磨砂卡片
struct AIGlassCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = AISpacing.lg,
        cornerRadius: CGFloat = AIRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AITheme.glassBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AITheme.glassStroke, lineWidth: 1)
                    )
            )
    }
}

// MARK: - AI风格按钮
struct AIPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AISpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AITypography.callout)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AISpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AIRadius.md)
                    .fill(isDisabled ? AnyShapeStyle(Color.gray) : AnyShapeStyle(AITheme.primaryGradient))
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
    }
}

// MARK: - 统计数据卡片
struct AIStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    let isPositiveTrend: Bool
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color = AITheme.accent,
        trend: String? = nil,
        isPositiveTrend: Bool = true
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.isPositiveTrend = isPositiveTrend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AISpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: isPositiveTrend ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(trend)
                            .font(AITypography.caption)
                    }
                    .foregroundColor(isPositiveTrend ? AITheme.success : AITheme.error)
                }
            }
            
            Text(value)
                .font(AITypography.title2)
                .fontWeight(.bold)
                .foregroundColor(AITheme.textPrimary)
            
            Text(title)
                .font(AITypography.caption)
                .foregroundColor(AITheme.textSecondary)
        }
        .padding(AISpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AIRadius.md)
                .fill(AITheme.surface)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 加载状态组件
struct AILoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: AISpacing.lg) {
            ZStack {
                Circle()
                    .stroke(AITheme.primaryGradient, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AITheme.accent)
            }
            
            Text(message)
                .font(AITypography.headline)
                .foregroundColor(AITheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - View扩展
extension View {
    /// 应用AI主题背景
    func aiBackground() -> some View {
        self.background(
            AITheme.backgroundGradient
                .ignoresSafeArea()
        )
    }
    
    /// 应用AI主题深色背景
    func aiDarkBackground() -> some View {
        self.background(
            AITheme.darkBackgroundGradient
                .ignoresSafeArea()
        )
    }
    
    /// AI风格的点击效果
    func aiTapEffect() -> some View {
        self.scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: UUID())
    }
}