//
//  FutureUIComponents.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  2025革命性UI组件库 - 完全重新设计
//

import SwiftUI

// MARK: - 未来感卡片系统

/// 革命性卡片组件 - 多维度设计
struct FutureCard<Content: View>: View {
    enum Style {
        case glass          // 超级玻璃拟态
        case neon           // 霓虹边框
        case floating       // 悬浮卡片
        case holographic    // 全息效果
        case particle       // 粒子边框
    }
    
    let content: Content
    let style: Style
    let isInteractive: Bool
    @State private var isHovered = false
    @State private var particleOffset: CGFloat = 0
    
    init(
        style: Style = .glass,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        content
            .padding(FluidSpacing.cardPadding)
            .background(cardBackground)
            .scaleEffect(isInteractive && isHovered ? 1.02 : 1.0)
            .animation(FluidAnimation.spring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if isInteractive {
                    withAnimation(FluidAnimation.bouncy) {
                        isHovered.toggle()
                    }
                }
            }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .glass:
            RoundedRectangle(cornerRadius: FluidRadius.card)
                .ultraGlass()
                .fluidShadow(FluidShadow.lg)
                
        case .neon:
            RoundedRectangle(cornerRadius: FluidRadius.card)
                .fill(FutureTheme.ultraGlass)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FluidRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: FluidRadius.card)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.8),
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 0.5)
                )
                .fluidShadow(FluidShadow.neon)
                
        case .floating:
            RoundedRectangle(cornerRadius: FluidRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FluidRadius.card))
                .fluidShadow(FluidShadow.xl)
                .offset(y: isHovered ? -4 : 0)
                
        case .holographic:
            RoundedRectangle(cornerRadius: FluidRadius.card)
                .fill(
                    AngularGradient(
                        colors: [
                            Color.clear,
                            Color.cyan.opacity(0.3),
                            Color.purple.opacity(0.3),
                            Color.pink.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startAngle: .degrees(particleOffset),
                        endAngle: .degrees(particleOffset + 180)
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FluidRadius.card))
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        particleOffset = 360
                    }
                }
                
        case .particle:
            RoundedRectangle(cornerRadius: FluidRadius.card)
                .ultraGlass()
                .overlay(
                    RoundedRectangle(cornerRadius: FluidRadius.card)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.6),
                                    Color.blue.opacity(0.4),
                                    Color.cyan.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                        )
                        .animation(FluidAnimation.pulse, value: isHovered)
                )
        }
    }
}

// MARK: - 革命性按钮系统

/// 未来感主要按钮
struct FuturePrimaryButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonSize {
        case small, medium, large, extraLarge
        
        var height: CGFloat {
            switch self {
            case .small: return FluidSizes.buttonSM
            case .medium: return FluidSizes.buttonMD
            case .large: return FluidSizes.buttonLG
            case .extraLarge: return FluidSizes.buttonXL
            }
        }
        
        var font: Font {
            switch self {
            case .small: return FutureTypography.labelSmall
            case .medium: return FutureTypography.labelMedium
            case .large: return FutureTypography.labelLarge
            case .extraLarge: return FutureTypography.heading4
            }
        }
    }
    
    enum ButtonStyle {
        case gradient       // 渐变按钮
        case glass         // 玻璃按钮
        case neon          // 霓虹按钮
        case holographic   // 全息按钮
    }
    
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.5
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        style: ButtonStyle = .gradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FluidSpacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.semibold)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(buttonBackground)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(FluidAnimation.spring, value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // 长按结束
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .onAppear {
            if style == .neon || style == .holographic {
                withAnimation(FluidAnimation.pulse) {
                    glowIntensity = 1.0
                }
            }
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return FluidSizes.iconSM
        case .medium: return FluidSizes.iconMD
        case .large: return FluidSizes.iconLG
        case .extraLarge: return FluidSizes.iconXL
        }
    }
    
    private var textColor: Color {
        switch style {
        case .gradient, .holographic: return .white
        case .glass, .neon: return FutureTheme.textOnGlass
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .gradient:
            RoundedRectangle(cornerRadius: FluidRadius.button)
                .fill(FutureTheme.primaryGradient)
                .fluidShadow(FluidShadow.lg)
                
        case .glass:
            RoundedRectangle(cornerRadius: FluidRadius.button)
                .ultraGlass()
                .overlay(
                    RoundedRectangle(cornerRadius: FluidRadius.button)
                        .stroke(FutureTheme.ultraGlassStroke, lineWidth: 1)
                )
                
        case .neon:
            RoundedRectangle(cornerRadius: FluidRadius.button)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: FluidRadius.button)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 1)
                        .opacity(glowIntensity)
                )
                .fluidShadow(FluidShadow.neon)
                
        case .holographic:
            RoundedRectangle(cornerRadius: FluidRadius.button)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.8),
                            Color.blue.opacity(0.6),
                            Color.cyan.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FluidRadius.button)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .fluidShadow(FluidShadow.glow)
        }
    }
}

// MARK: - 革命性数据卡片

/// 未来感健康数据卡片
struct FutureHealthCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let healthStatus: HealthStatus
    let trend: TrendData?
    let isAnimated: Bool
    
    enum HealthStatus {
        case excellent, good, warning, critical
        
        var gradient: LinearGradient {
            switch self {
            case .excellent: return FutureTheme.healthExcellent
            case .good: return FutureTheme.healthGood
            case .warning: return FutureTheme.healthWarning
            case .critical: return FutureTheme.healthCritical
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return Color.green
            case .good: return Color.blue
            case .warning: return Color.orange
            case .critical: return Color.red
            }
        }
    }
    
    struct TrendData {
        let percentage: Double
        let isPositive: Bool
        let description: String?
    }
    
    @State private var animatedValue: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    init(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String,
        healthStatus: HealthStatus = .good,
        trend: TrendData? = nil,
        isAnimated: Bool = true
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.healthStatus = healthStatus
        self.trend = trend
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        FutureCard(style: .glass, isInteractive: true) {
            VStack(spacing: FluidSpacing.medium) {
                // 顶部：图标和状态
                HStack {
                    ZStack {
                        Circle()
                            .fill(healthStatus.gradient)
                            .frame(width: 50, height: 50)
                            .scaleEffect(pulseScale)
                            .animation(FluidAnimation.pulse, value: pulseScale)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(String(format: "%.1f%%", abs(trend.percentage)))
                                .font(FutureTypography.labelSmall)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(trend.isPositive ? Color.green : Color.red)
                        .padding(.horizontal, FluidSpacing.small)
                        .padding(.vertical, FluidSpacing.tiny)
                        .background(
                            Capsule()
                                .fill(
                                    (trend.isPositive ? Color.green : Color.red)
                                        .opacity(0.15)
                                )
                        )
                    }
                }
                
                // 中部：数值显示
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    if isAnimated {
                        AnimatedCounter(
                            value: Double(value.replacingOccurrences(of: ",", with: "")) ?? 0,
                            font: FutureTypography.displayMD
                        )
                    } else {
                        Text(value)
                            .font(FutureTypography.displayMD)
                            .fontWeight(.bold)
                    }
                    
                    if let unit = unit {
                        Text(unit)
                            .font(FutureTypography.labelMedium)
                            .foregroundColor(FutureTheme.textSecondary)
                    }
                }
                .foregroundColor(FutureTheme.textPrimary)
                
                // 底部：标题和描述
                VStack(spacing: FluidSpacing.tiny) {
                    Text(title)
                        .font(FutureTypography.labelLarge)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    if let trend = trend, let description = trend.description {
                        Text(description)
                            .font(FutureTypography.caption)
                            .foregroundColor(FutureTheme.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.5)) {
                    animatedValue = Double(value.replacingOccurrences(of: ",", with: "")) ?? 0
                }
                
                // 脉冲动画
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(FluidAnimation.gentle) {
                        pulseScale = pulseScale == 1.0 ? 1.1 : 1.0
                    }
                }
            }
        }
    }
}

// MARK: - 动画计数器

struct AnimatedCounter: View {
    let value: Double
    let font: Font
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: "%.0f", displayValue))
            .font(font)
            .fontWeight(.bold)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { newValue in
                withAnimation(.easeOut(duration: 1.0)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - 革命性加载组件

/// 未来感加载视图
struct FutureLoadingView: View {
    let message: String
    let style: LoadingStyle
    
    enum LoadingStyle {
        case orbital        // 轨道旋转
        case quantum       // 量子效果
        case neural        // 神经网络
        case hologram      // 全息投影
    }
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    init(message: String = "正在加载...", style: LoadingStyle = .orbital) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: FluidSpacing.large) {
            loadingIndicator
            
            if !message.isEmpty {
                Text(message)
                    .font(FutureTypography.bodyMedium)
                    .foregroundColor(FutureTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .orbital:
            ZStack {
                // 外圈
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                
                // 内圈
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.clear],
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-rotation * 0.8))
                
                // 中心点
                Circle()
                    .fill(FutureTheme.primaryGradient)
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale)
            }
            
        case .quantum:
            HStack(spacing: FluidSpacing.small) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            1.0 + 0.5 * sin(rotation * 0.02 + Double(index) * 0.8)
                        )
                        .opacity(0.3 + 0.7 * sin(rotation * 0.015 + Double(index) * 0.6))
                }
            }
            
        case .neural:
            ZStack {
                ForEach(0..<8) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cyan)
                        .frame(width: 20, height: 4)
                        .offset(y: -25)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .opacity(
                            index == Int((rotation / 45).truncatingRemainder(dividingBy: 8)) ? 1.0 : 0.3
                        )
                }
            }
            .frame(width: 50, height: 50)
            
        case .hologram:
            VStack(spacing: 2) {
                ForEach(0..<6) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: 30 - CGFloat(index) * 3,
                            height: 3
                        )
                        .opacity(opacity + Double(index) * 0.1)
                        .scaleEffect(x: 1.0 + sin(rotation * 0.01 + Double(index) * 0.5) * 0.3)
                }
            }
        }
    }
    
    private func startAnimation() {
        switch style {
        case .orbital:
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.5
            }
            
        case .quantum, .neural:
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
        case .hologram:
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - 革命性标签系统

/// 未来感标签
struct FutureTag: View {
    let text: String
    let style: TagStyle
    
    enum TagStyle {
        case neon(Color)
        case glass
        case gradient
        case holographic
    }
    
    @State private var glowIntensity: Double = 0.5
    
    init(_ text: String, style: TagStyle = .glass) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(FutureTypography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, FluidSpacing.medium)
            .padding(.vertical, FluidSpacing.small)
            .background(tagBackground)
            .clipShape(Capsule())
            .onAppear {
                if case .neon(_) = style {
                    withAnimation(FluidAnimation.pulse) {
                        glowIntensity = 1.0
                    }
                }
            }
    }
    
    private var textColor: Color {
        switch style {
        case .neon(_), .gradient, .holographic: return .white
        case .glass: return FutureTheme.textOnGlass
        }
    }
    
    @ViewBuilder
    private var tagBackground: some View {
        switch style {
        case .neon(let color):
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(color, lineWidth: 1.5)
                        .blur(radius: 1)
                        .opacity(glowIntensity)
                )
                
        case .glass:
            Capsule()
                .ultraGlass()
                
        case .gradient:
            Capsule()
                .fill(FutureTheme.primaryGradient)
                
        case .holographic:
            Capsule()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.cyan,
                            Color.blue,
                            Color.purple,
                            Color.pink,
                            Color.cyan
                        ],
                        center: .center
                    )
                )
        }
    }
}

// MARK: - 革命性空状态

/// 未来感空状态视图
struct FutureEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var floatingOffset: CGFloat = 0
    @State private var glowRadius: CGFloat = 30
    
    var body: some View {
        FutureCard(style: .holographic) {
            VStack(spacing: FluidSpacing.large) {
                // 浮动图标
                ZStack {
                    Circle()
                        .fill(FutureTheme.primaryGradient)
                        .frame(width: 100, height: 100)
                        .blur(radius: glowRadius)
                        .opacity(0.6)
                    
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white)
                }
                .offset(y: floatingOffset)
                .animation(FluidAnimation.floating, value: floatingOffset)
                
                // 文本内容
                VStack(spacing: FluidSpacing.medium) {
                    Text(title)
                        .font(FutureTypography.heading2)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // 操作按钮
                if let actionTitle = actionTitle, let action = action {
                    FuturePrimaryButton(
                        actionTitle,
                        icon: "plus.circle.fill",
                        style: .holographic,
                        action: action
                    )
                    .padding(.top, FluidSpacing.medium)
                }
            }
        }
        .onAppear {
            withAnimation(FluidAnimation.floating) {
                floatingOffset = -10
            }
            withAnimation(FluidAnimation.pulse) {
                glowRadius = 50
            }
        }
    }
}