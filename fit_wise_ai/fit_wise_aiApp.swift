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
 * 4. 监听应用生命周期变化（权限同步）
 * 
 * FitWise AI 是一个智能健身助手应用，通过分析用户的健康数据
 * 提供个性化的运动、营养和休息建议。
 */
@main
struct FitWiseAIApp: App {
    @StateObject private var healthKitService = HealthKitService()
    @Environment(\.scenePhase) private var scenePhase
    
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
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }
    
    /**
     * 处理应用生命周期变化
     * 
     * 基于Apple官方文档：当应用从后台返回前台时，
     * 应该重新检查HealthKit权限状态，因为用户可能在健康App中更改了权限
     */
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("🟢 FitWiseAIApp: 应用进入活跃状态")
            // 只有从后台返回时才检查权限（避免频繁检查）
            if oldPhase == .background {
                print("🔄 FitWiseAIApp: 从后台返回，检查HealthKit权限状态")
                Task { @MainActor in
                    await healthKitService.checkCurrentAuthorizationStatus()
                }
            }
            
        case .inactive:
            print("🟡 FitWiseAIApp: 应用进入非活跃状态")
            
        case .background:
            print("🟤 FitWiseAIApp: 应用进入后台")
            
        @unknown default:
            print("🟠 FitWiseAIApp: 未知应用状态: \(newPhase)")
        }
    }
}
