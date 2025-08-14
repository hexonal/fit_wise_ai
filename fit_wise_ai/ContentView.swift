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
 * 使用 TabView 组件提供底部标签导航，包含两个主要模块：
 * - 首页：显示健康数据概览和 AI 建议
 * - 设置：应用配置和用户偏好设置
 */
struct ContentView: View {
    var body: some View {
        TabView {
            // 首页标签 - 健康数据展示和 AI 建议
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
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
