//
//  ModernUIComponents.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  现代化UI组件库
//

import SwiftUI

// MARK: - 现代化卡片组件系统

/// 现代化卡片 - 支持多种样式
struct ModernCard<Content: View>: View {
    enum Style {
        case elevated     // 带阴影的悬浮卡片
        case filled      // 实色填充卡片
        case outlined    // 边框卡片
        case glass       // 玻璃拟态卡片
        case gradient    // 渐变卡片
    }
    
    let content: Content
    let style: Style
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        style: Style = .elevated,
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.systemBackground))
                .modernShadow(ModernShadow.lg)
                
        case .filled:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.secondarySystemBackground))
                
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                
        case .gradient:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .modernShadow(ModernShadow.xl)
        }
    }
}

// MARK: - 现代化按钮组件系统

/// 现代化主要按钮
struct ModernPrimaryButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    enum ButtonSize {
        case small, medium, large, extraLarge
        
        var height: CGFloat {
            switch self {
            case .small: return ModernSizes.buttonSmall
            case .medium: return ModernSizes.buttonMedium
            case .large: return ModernSizes.buttonLarge
            case .extraLarge: return ModernSizes.buttonExtraLarge
            }
        }
        
        var font: Font {
            switch self {
            case .small: return ModernTypography.caption
            case .medium: return ModernTypography.callout
            case .large: return ModernTypography.bodyMedium
            case .extraLarge: return ModernTypography.headline
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return ModernSizes.iconSM
            case .medium: return ModernSizes.iconMD
            case .large: return ModernSizes.iconLG
            case .extraLarge: return ModernSizes.iconXL
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isDisabled ? 
                        AnyShapeStyle(Color.gray) : 
                        AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .scaleEffect(isPressed ? 0.98 : 1.0)
            )
        }
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // 长按结束
        } onPressingChanged: { pressing in
            withAnimation(ModernAnimation.snappy) {
                isPressed = pressing
            }
        }
        .animation(ModernAnimation.spring, value: isLoading)
    }
}

/// 现代化次要按钮
struct ModernSecondaryButton: View {
    let title: String
    let icon: String?
    let size: ModernPrimaryButton.ButtonSize
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ModernPrimaryButton.ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color.blue)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(isPressed ? 0.98 : 1.0)
            )
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // 长按结束
        } onPressingChanged: { pressing in
            withAnimation(ModernAnimation.snappy) {
                isPressed = pressing
            }
        }
    }
}

/// 现代化图标按钮
struct ModernIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        icon: String,
        size: CGFloat = ModernSizes.iconLG,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(Color.primary)
                .frame(width: size + 16, height: size + 16)
                .background(
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                )
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // 长按结束
        } onPressingChanged: { pressing in
            withAnimation(ModernAnimation.snappy) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - 现代化统计卡片

/// 增强版统计数据卡片
struct ModernStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendInfo?
    let isCompact: Bool
    
    struct TrendInfo {
        let value: String
        let isPositive: Bool
        let description: String?
    }
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color = Color.blue,
        trend: TrendInfo? = nil,
        isCompact: Bool = false
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.isCompact = isCompact
    }
    
    var body: some View {
        ModernCard(style: .elevated, padding: isCompact ? 12 : 16) {
            VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                // 顶部：图标和趋势
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: isCompact ? 32 : 40, height: isCompact ? 32 : 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: isCompact ? 16 : 20, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                    
                    if let trend = trend, !isCompact {
                        HStack(spacing: 4) {
                            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text(trend.value)
                                .font(ModernTypography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(trend.isPositive ? Color.green : Color.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    (trend.isPositive ? Color.green : Color.red)
                                        .opacity(0.1)
                                )
                        )
                    }
                }
                
                // 中部：数值
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(isCompact ? ModernTypography.headline : ModernTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                    
                    Text(title)
                        .font(isCompact ? ModernTypography.caption : ModernTypography.callout)
                        .foregroundColor(Color.secondary)
                }
                
                // 底部：趋势描述（仅非紧凑模式）
                if let trend = trend, let description = trend.description, !isCompact {
                    Text(description)
                        .font(ModernTypography.caption)
                        .foregroundColor(Color.gray)
                        .lineLimit(2)
                }
            }
        }
        .modernShadow((color: color.opacity(0.15), radius: 12, x: 0, y: 4))
    }
}

// MARK: - 现代化加载组件

/// 现代化加载视图
struct ModernLoadingView: View {
    let message: String
    let style: LoadingStyle
    
    enum LoadingStyle {
        case spinner      // 旋转指示器
        case pulse       // 脉冲效果
        case dots        // 点点加载
        case shimmer     // 微光效果
    }
    
    @State private var animationValue: CGFloat = 0
    
    init(message: String, style: LoadingStyle = .spinner) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 20) {
            loadingIndicator
            
            if !message.isEmpty {
                Text(message)
                    .font(ModernTypography.callout)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        Group {
            if style == .spinner {
                spinnerView
            } else if style == .pulse {
                pulseView
            } else if style == .dots {
                dotsView
            } else {
                shimmerView
            }
        }
    }
    
    private var spinnerView: some View {
        ZStack {
            Circle()
                .stroke(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(animationValue * 360))
            
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.blue)
        }
    }
    
    private var pulseView: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 50, height: 50)
            .scaleEffect(1.0 + animationValue * 0.3)
            .opacity(1.0 - animationValue * 0.5)
    }
    
    private var dotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                let offset = Double(index) * 0.5
                let scale = 1.0 + sin(animationValue * 2 * Double.pi + offset) * 0.3
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .scaleEffect(scale)
            }
        }
    }
    
    private var shimmerView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(UIColor.secondarySystemBackground))
            .frame(width: 200, height: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 4)
                    .offset(x: (animationValue - 0.5) * 200)
            )
    }
    
    private func startAnimation() {
        switch style {
        case .spinner:
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationValue = 1
            }
        case .pulse:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animationValue = 1
            }
        case .dots:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationValue = 1
            }
        case .shimmer:
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animationValue = 1.3
            }
        }
    }
}

// MARK: - 现代化状态视图

/// 现代化空状态视图
struct ModernEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        ModernCard(style: .filled, padding: 32) {
            VStack(spacing: 20) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                // 文本
                VStack(spacing: 12) {
                    Text(title)
                        .font(ModernTypography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(ModernTypography.body)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // 操作按钮
                if let actionTitle = actionTitle, let action = action {
                    ModernPrimaryButton(actionTitle, action: action)
                        .padding(.top, 12)
                }
            }
        }
    }
}

// MARK: - 现代化标签和徽章

/// 现代化标签
struct ModernTag: View {
    let text: String
    let style: TagStyle
    let size: TagSize
    
    enum TagStyle {
        case filled(Color)
        case outlined(Color)
        case soft(Color)
    }
    
    enum TagSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return ModernTypography.caption2
            case .medium: return ModernTypography.caption
            case .large: return ModernTypography.footnote
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }
    
    init(_ text: String, style: TagStyle, size: TagSize = .medium) {
        self.text = text
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(size.padding)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var textColor: Color {
        switch style {
        case .filled(let color):
            return color == .white ? .black : .white
        case .outlined(let color), .soft(let color):
            return color
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled(let color):
            return color
        case .outlined(_):
            return Color.clear
        case .soft(let color):
            return color.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled(_), .soft(_):
            return Color.clear
        case .outlined(let color):
            return color
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .filled(_), .soft(_):
            return 0
        case .outlined(_):
            return 1
        }
    }
}

// MARK: - 现代化进度指示器

/// 现代化进度条
struct ModernProgressBar: View {
    let progress: Double // 0.0 到 1.0
    let height: CGFloat
    let backgroundColor: Color
    let foregroundGradient: LinearGradient
    let animated: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 8,
        backgroundColor: Color = Color(UIColor.secondarySystemBackground),
        foregroundGradient: LinearGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing),
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundGradient = foregroundGradient
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)
                
                // 进度条
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundGradient)
                    .frame(
                        width: geometry.size.width * (animated ? animatedProgress : progress),
                        height: height
                    )
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newProgress in
            if animated {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newProgress
                }
            }
        }
    }
}