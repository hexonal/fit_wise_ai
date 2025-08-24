//
//  ContentView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

/**
 * 应用程序的主视图
 * 
 * 这是应用的根视图，负责管理主要的导航结构。
 * 使用 TabView 组件提供底部标签导航，包含三个主要模块：
 * - 首页：显示7天健康数据概览和趋势
 * - AI建议：基于健康数据的个性化建议
 * - 设置：应用配置和用户偏好设置
 */
struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // AI主题渐变背景
            (colorScheme == .dark ? AITheme.darkBackgroundGradient : AITheme.backgroundGradient)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // 首页标签 - 健康数据展示
                HomeView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("首页")
                    }
                    .tag(0)
                
                // AI建议标签 - 智能健康建议
                AIAdviceView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "sparkles" : "sparkles")
                        Text("AI建议")
                    }
                    .tag(1)
                
                // 设置标签 - 应用配置界面
                SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "gear.circle.fill" : "gear.circle")
                        Text("设置")
                    }
                    .tag(2)
            }
            .tint(AITheme.accent) // 使用AI主题色
            .background(.clear) // 透明背景以显示渐变
            .onAppear {
                // 自定义TabBar外观
                setupTabBarAppearance()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        // 设置选中和未选中状态的颜色
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AITheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AITheme.accent)]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitService())
}
