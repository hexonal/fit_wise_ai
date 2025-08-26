//
//  ContentView_Future.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  革命性主视图 - 完全重新设计
//

import SwiftUI

/// 2025未来感主视图 - 完全替换原有设计
struct FutureContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    // 动画状态
    @State private var tabAnimation: CGFloat = 0
    @State private var backgroundOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 革命性背景系统
            revolutionaryBackground
            
            // 主要内容区域
            TabView(selection: $selectedTab) {
                // 未来感首页
                FutureHomeView()
                    .tabItem {
                        tabIcon("house.fill", "首页", isSelected: selectedTab == 0)
                    }
                    .tag(0)
                
                // 未来感AI建议页
                FutureAIAdviceView()
                    .tabItem {
                        tabIcon("sparkles", "AI建议", isSelected: selectedTab == 1)
                    }
                    .tag(1)
                
                // 设置页（使用现有的）
                SettingsView()
                    .tabItem {
                        tabIcon("gearshape.fill", "设置", isSelected: selectedTab == 2)
                    }
                    .tag(2)
            }
            .tint(.clear) // 移除默认tint，使用自定义设计
            
            // 自定义底部导航栏
            VStack {
                Spacer()
                customTabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            setupBackgroundAnimation()
        }
    }
    
    // MARK: - 革命性背景系统
    
    private var revolutionaryBackground: some View {
        ZStack {
            // 基础渐变背景
            FutureTheme.immersiveBackground
                .ignoresSafeArea(.all)
            
            // 动态粒子效果
            ParticleField()
                .ignoresSafeArea(.all)
                .opacity(0.4)
            
            // 浮动光效
            GeometryReader { geometry in
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.1),
                                    Color.blue.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .center,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .position(
                            x: geometry.size.width * (0.2 + Double(index) * 0.2),
                            y: geometry.size.height * 0.3 + sin(backgroundOffset + Double(index)) * 100
                        )
                        .blur(radius: 30)
                }
            }
            .animation(FluidAnimation.floating, value: backgroundOffset)
        }
    }
    
    // MARK: - 自定义未来感标签栏
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(FluidAnimation.bouncy) {
                        selectedTab = index
                        tabAnimation = CGFloat(index)
                    }
                }) {
                    VStack(spacing: FluidSpacing.tiny) {
                        ZStack {
                            // 选中状态背景
                            if selectedTab == index {
                                Circle()
                                    .fill(FutureTheme.primaryGradient)
                                    .frame(width: 50, height: 50)
                                    .scaleEffect(1.1)
                                    .fluidShadow(FluidShadow.glow)
                            }
                            
                            Image(systemName: tabIconName(for: index))
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(
                                    selectedTab == index ? .white : FutureTheme.textSecondary
                                )
                        }
                        
                        Text(tabTitle(for: index))
                            .font(FutureTypography.labelSmall)
                            .foregroundColor(
                                selectedTab == index ? FutureTheme.textAccent : FutureTheme.textTertiary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                .animation(FluidAnimation.spring, value: selectedTab)
            }
        }
        .padding(.horizontal, FluidSpacing.large)
        .padding(.vertical, FluidSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: FluidRadius.xl)
                .ultraGlass()
                .fluidShadow(FluidShadow.lg)
        )
        .padding(.horizontal, FluidSpacing.large)
        .padding(.bottom, FluidSpacing.medium)
    }
    
    // MARK: - 标签辅助方法
    
    private func tabIcon(_ systemName: String, _ title: String, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
            Text(title)
                .font(.caption2)
        }
    }
    
    private func tabIconName(for index: Int) -> String {
        switch index {
        case 0: return selectedTab == 0 ? "house.fill" : "house"
        case 1: return "sparkles"
        case 2: return selectedTab == 2 ? "gearshape.fill" : "gearshape"
        default: return "questionmark"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "首页"
        case 1: return "AI建议"
        case 2: return "设置"
        default: return ""
        }
    }
    
    // MARK: - 动画设置
    
    private func setupBackgroundAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                backgroundOffset += 0.02
            }
        }
    }
}

#Preview {
    FutureContentView()
        .environmentObject(HealthKitService())
}