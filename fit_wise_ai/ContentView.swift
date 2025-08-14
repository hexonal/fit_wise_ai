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
    var body: some View {
        TabView {
            // 首页标签 - 健康数据展示
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            
            // AI建议标签 - 智能健康建议
            AIAdviceView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI建议")
                }
            
            // 设置标签 - 应用配置界面
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
        .accentColor(.blue) // 设置标签栏的主题色为蓝色
    }
}

#Preview {
    ContentView()
}
