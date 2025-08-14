//
//  fit_wise_aiApp.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

/**
 * FitWise AI 应用主入口
 * 
 * 这是应用的启动点，负责：
 * 1. 定义应用的根场景
 * 2. 设置主窗口组
 * 3. 初始化应用的根视图
 * 
 * FitWise AI 是一个智能健身助手应用，通过分析用户的健康数据
 * 提供个性化的运动、营养和休息建议。
 */
@main
struct FitWiseAIApp: App {
    @StateObject private var healthKitService = HealthKitService()
    
    init() {
        print("🚀 FitWiseAIApp: 应用启动")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .onAppear {
                    print("🚀 FitWiseAIApp: ContentView 显示")
                }
        }
    }
}
