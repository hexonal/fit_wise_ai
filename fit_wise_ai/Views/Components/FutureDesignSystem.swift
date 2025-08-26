//
//  FutureDesignSystem.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  全新现代化设计系统 - 完全替换版本
//

import SwiftUI

// MARK: - 2025现代化主题系统

/// 全新设计主题 - 完全替换原有设计
struct FutureTheme {
    
    // MARK: - 动态品牌色系统
    
    /// 主品牌渐变 - 5色动态渐变
    static let primaryGradient = AngularGradient(
        colors: [
            Color(red: 0.3, green: 0.1, blue: 0.9),    // 深紫
            Color(red: 0.1, green: 0.4, blue: 1.0),    // 蓝色
            Color(red: 0.0, green: 0.7, blue: 0.9),    // 青色
            Color(red: 0.2, green: 0.9, blue: 0.5),    // 绿色
            Color(red: 0.3, green: 0.1, blue: 0.9)     // 回到起点
        ],
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )
    
    /// 健康状态渐变系统
    static let healthExcellent = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.8, blue: 0.4),
            Color(red: 0.2, green: 0.9, blue: 0.6)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let healthGood = LinearGradient(
        colors: [
            Color(red: 0.5, green: 0.8, blue: 0.2),
            Color(red: 0.7, green: 0.9, blue: 0.4)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let healthWarning = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.7, blue: 0.2),
            Color(red: 1.0, green: 0.8, blue: 0.4)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let healthCritical = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.3, blue: 0.3),
            Color(red: 1.0, green: 0.5, blue: 0.5)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    // MARK: - 沉浸式背景系统
    
    /// 主背景 - 动态粒子效果背景
    static let immersiveBackground = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.02, blue: 0.1),   // 深蓝黑
            Color(red: 0.05, green: 0.05, blue: 0.2),   // 蓝黑
            Color(red: 0.1, green: 0.05, blue: 0.25),   // 紫蓝
            Color(red: 0.02, green: 0.02, blue: 0.1)    // 回到起点
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 浅色模式背景 - 纯净科技感
    static let lightBackground = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 1.0),
            Color(red: 0.95, green: 0.98, blue: 1.0),
            Color(red: 0.92, green: 0.97, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 新一代玻璃拟态
    
    /// 超级玻璃效果 - 多层玻璃
    static let ultraGlass = Color.white.opacity(0.08)
    static let ultraGlassStroke = Color.white.opacity(0.15)
    static let ultraGlassAccent = Color.white.opacity(0.25)
    
    /// 霓虹玻璃效果
    static let neonGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color(red: 0.3, green: 0.4, blue: 1.0).opacity(0.1),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 语义化颜色 2.0
    
    /// 文本颜色 - 高对比度
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let textAccent = Color(red: 0.2, green: 0.4, blue: 1.0)
    static let textOnGlass = Color.white
    static let textOnDark = Color.white
    
    /// 表面颜色 - 层次化
    static let surfaceBase = Color(UIColor.systemBackground)
    static let surfaceElevated = Color.white.opacity(0.05)
    static let surfaceCard = Color.white.opacity(0.08)
    static let surfaceModal = Color.black.opacity(0.4)
    
    /// 交互颜色
    static let interactive = Color(red: 0.2, green: 0.4, blue: 1.0)
    static let interactivePressed = Color(red: 0.1, green: 0.3, blue: 0.9)
    static let interactiveDisabled = Color.gray.opacity(0.3)
}

// MARK: - 未来感字体系统

struct FutureTypography {
    // 显示字体 - 用于重要标题
    static let displayXL = Font.system(size: 48, weight: .black, design: .rounded)
    static let displayLG = Font.system(size: 36, weight: .heavy, design: .rounded)
    static let displayMD = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySM = Font.system(size: 24, weight: .bold, design: .rounded)
    
    // 标题字体
    static let heading1 = Font.system(size: 32, weight: .bold, design: .rounded)
    static let heading2 = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let heading3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let heading4 = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // 正文字体
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // 标签字体
    static let labelLarge = Font.system(size: 16, weight: .medium, design: .rounded)
    static let labelMedium = Font.system(size: 14, weight: .medium, design: .rounded)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .rounded)
    
    // 特殊字体
    static let mono = Font.system(.body, design: .monospaced)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let micro = Font.system(size: 10, weight: .regular, design: .rounded)
}

// MARK: - 流体间距系统

struct FluidSpacing {
    // 基础间距 - 8的倍数系统
    static let space1: CGFloat = 4    // 0.25rem
    static let space2: CGFloat = 8    // 0.5rem
    static let space3: CGFloat = 12   // 0.75rem
    static let space4: CGFloat = 16   // 1rem
    static let space5: CGFloat = 20   // 1.25rem
    static let space6: CGFloat = 24   // 1.5rem
    static let space8: CGFloat = 32   // 2rem
    static let space10: CGFloat = 40  // 2.5rem
    static let space12: CGFloat = 48  // 3rem
    static let space16: CGFloat = 64  // 4rem
    static let space20: CGFloat = 80  // 5rem
    static let space24: CGFloat = 96  // 6rem
    
    // 语义化间距
    static let micro = space1
    static let tiny = space2
    static let small = space3
    static let medium = space4
    static let large = space6
    static let xlarge = space8
    static let xxlarge = space10
    static let xxxlarge = space12
    
    // 布局间距
    static let componentGap = space4      // 组件间距离
    static let sectionGap = space8        // 区块间距离
    static let pageMargin = space6        // 页面边距
    static let cardPadding = space6       // 卡片内边距
}

// MARK: - 现代化圆角系统

struct FluidRadius {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let full: CGFloat = 999
    
    // 语义化圆角
    static let button: CGFloat = lg
    static let card: CGFloat = xl
    static let modal: CGFloat = xxl
    static let avatar: CGFloat = full
}

// MARK: - 阴影系统 2.0

struct FluidShadow {
    // 基础阴影
    static let xs = (color: Color.black.opacity(0.03), radius: CGFloat(1), x: CGFloat(0), y: CGFloat(1))
    static let sm = (color: Color.black.opacity(0.06), radius: CGFloat(3), x: CGFloat(0), y: CGFloat(2))
    static let md = (color: Color.black.opacity(0.1), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(4))
    static let lg = (color: Color.black.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(8))
    static let xl = (color: Color.black.opacity(0.2), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(12))
    static let xxl = (color: Color.black.opacity(0.25), radius: CGFloat(32), x: CGFloat(0), y: CGFloat(16))
    
    // 特殊阴影
    static let glow = (color: FutureTheme.interactive.opacity(0.4), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(0))
    static let neon = (color: Color.cyan.opacity(0.6), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(0))
    static let health = (color: Color.green.opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
}

// MARK: - 流体动画系统

struct FluidAnimation {
    // 时长定义
    static let instant: Double = 0.1
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.35
    static let slower: Double = 0.5
    static let slowest: Double = 0.8
    
    // 预定义动画
    static let spring = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)
    static let bouncy = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)
    static let smooth = Animation.easeInOut(duration: normal)
    static let snappy = Animation.easeOut(duration: fast)
    static let gentle = Animation.easeInOut(duration: slow)
    static let elastic = Animation.interpolatingSpring(stiffness: 200, damping: 15)
    
    // 特殊动画
    static let morphing = Animation.easeInOut(duration: slower)
    static let floating = Animation.easeInOut(duration: slowest).repeatForever(autoreverses: true)
    static let pulse = Animation.easeInOut(duration: slow).repeatForever(autoreverses: true)
}

// MARK: - 现代化尺寸系统

struct FluidSizes {
    // 按钮尺寸
    static let buttonXS: CGFloat = 28
    static let buttonSM: CGFloat = 36
    static let buttonMD: CGFloat = 44
    static let buttonLG: CGFloat = 52
    static let buttonXL: CGFloat = 64
    
    // 图标尺寸
    static let iconXS: CGFloat = 12
    static let iconSM: CGFloat = 16
    static let iconMD: CGFloat = 20
    static let iconLG: CGFloat = 24
    static let iconXL: CGFloat = 32
    static let iconXXL: CGFloat = 48
    
    // 头像尺寸
    static let avatarXS: CGFloat = 24
    static let avatarSM: CGFloat = 32
    static let avatarMD: CGFloat = 48
    static let avatarLG: CGFloat = 64
    static let avatarXL: CGFloat = 96
    
    // 卡片尺寸
    static let cardMinHeight: CGFloat = 80
    static let cardMediumHeight: CGFloat = 140
    static let cardLargeHeight: CGFloat = 200
    static let cardXLHeight: CGFloat = 280
    
    // 输入框尺寸
    static let inputSM: CGFloat = 36
    static let inputMD: CGFloat = 44
    static let inputLG: CGFloat = 52
}

// MARK: - 革命性View扩展

extension View {
    /// 应用未来感背景
    func futureBackground() -> some View {
        self.background(
            ZStack {
                FutureTheme.immersiveBackground
                    .ignoresSafeArea()
                
                // 粒子效果层
                ParticleField()
                    .ignoresSafeArea()
                    .opacity(0.3)
            }
        )
    }
    
    /// 超级玻璃效果
    func ultraGlass(
        cornerRadius: CGFloat = FluidRadius.card,
        strokeWidth: CGFloat = 1.5
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(FutureTheme.ultraGlass)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(FutureTheme.ultraGlassStroke, lineWidth: strokeWidth)
                )
        )
    }
    
    /// 霓虹玻璃效果
    func neonGlass(
        cornerRadius: CGFloat = FluidRadius.card
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(FutureTheme.neonGlass)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.cyan.opacity(0.3),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    /// 流体阴影
    func fluidShadow(
        _ shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = FluidShadow.md
    ) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 悬浮动画
    func hoverEffect() -> some View {
        self.scaleEffect(1.0)
            .animation(FluidAnimation.spring, value: UUID())
    }
    
    /// 渐变边框
    func gradientBorder(
        gradient: LinearGradient = LinearGradient(
            colors: [FutureTheme.interactive, Color.cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = FluidRadius.lg
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(gradient, lineWidth: lineWidth)
        )
    }
    
    /// 脉冲效果
    @ViewBuilder
    func pulseEffect(isActive: Bool = true) -> some View {
        if isActive {
            self.scaleEffect(1.05)
                .animation(FluidAnimation.pulse, value: isActive)
        } else {
            self
        }
    }
}

// MARK: - 粒子系统组件

struct ParticleField: View {
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
        var velocity: CGSize
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)],
                            startPoint: .center,
                            endPoint: .center
                        )
                    )
                    .frame(width: 2 * particle.scale, height: 2 * particle.scale)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func initializeParticles() {
        particles = (0..<50).map { _ in
            Particle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.1...0.8),
                scale: CGFloat.random(in: 0.5...2.0),
                velocity: CGSize(
                    width: CGFloat.random(in: -0.5...0.5),
                    height: CGFloat.random(in: -0.8...0.8)
                )
            )
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].x += particles[i].velocity.width
            particles[i].y += particles[i].velocity.height
            
            // 边界检查
            if particles[i].x < 0 || particles[i].x > UIScreen.main.bounds.width {
                particles[i].velocity.width *= -1
            }
            if particles[i].y < 0 || particles[i].y > UIScreen.main.bounds.height {
                particles[i].velocity.height *= -1
            }
            
            // 透明度变化
            particles[i].opacity += Double.random(in: -0.02...0.02)
            particles[i].opacity = max(0.1, min(0.8, particles[i].opacity))
        }
    }
}