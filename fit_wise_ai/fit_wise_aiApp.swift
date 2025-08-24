//
//  fit_wise_aiApp.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

/**
 * FitWise AI 应用主入口 - 重构版
 * 
 * 基于Actor Model + Event Sourcing架构的新应用入口：
 * 1. 使用ApplicationCoordinator协调整个应用
 * 2. 采用事件驱动的服务架构
 * 3. 提供全面的错误处理和恢复机制
 * 4. 支持实时诊断和监控
 * 
 * 架构优势：
 * - 高并发处理能力（Actor Model）
 * - 完整的操作审计跟踪（Event Sourcing）
 * - 模块化和可扩展设计
 * - 强大的错误恢复能力
 */
@main
struct FitWiseAIApp: App {
    /// 应用程序协调器（新架构的核心）
    @StateObject private var coordinator = ApplicationCoordinator()
    /// 环境场景阶段
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        print("🚀 FitWiseAIApp: 启动新架构版本")
        print("📐 架构: Actor Model + Event Sourcing")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch coordinator.applicationState {
                case .initializing:
                    InitializationView(
                        progress: coordinator.initializationProgress,
                        systemHealth: coordinator.systemHealth
                    )
                case .ready:
                    ContentView()
                        .environmentObject(coordinator)
                        .environmentObject(coordinator.healthKitService)
                        .environmentObject(coordinator.aiService)
                case .degraded:
                    DegradedModeView()
                        .environmentObject(coordinator)
                case .error:
                    ErrorRecoveryView(
                        error: coordinator.criticalError,
                        onRetry: {
                            Task {
                                await coordinator.resetApplication()
                            }
                        }
                    )
                }
            }
            .onAppear {
                print("🚀 FitWiseAIApp: ContentView 显示")
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                handleMemoryWarning()
            }
        }
    }
    
    /**
     * 处理应用生命周期变化
     * 
     * 新架构下的生命周期管理：
     * - 通过事件系统记录状态变化
     * - 自动触发健康检查和数据同步
     * - 支持后台任务管理
     */
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        Task {
            switch newPhase {
            case .active:
                print("🟢 FitWiseAIApp: 应用进入活跃状态")
                
                // 从后台返回时触发健康检查
                if oldPhase == .background {
                    print("🔄 FitWiseAIApp: 从后台返回，触发系统健康检查")
                    await coordinator.triggerHealthCheck()
                }
                
            case .inactive:
                print("🟡 FitWiseAIApp: 应用进入非活跃状态")
                
            case .background:
                print("🟤 FitWiseAIApp: 应用进入后台")
                // 在后台模式下，某些Actor可能需要暂停处理
                
            @unknown default:
                print("🟠 FitWiseAIApp: 未知应用状态: \(newPhase)")
            }
        }
    }
    
    /**
     * 处理内存警告
     */
    private func handleMemoryWarning() {
        print("⚠️ FitWiseAIApp: 收到内存警告")
        
        Task {
            // 可以在这里触发内存清理
            // 例如清理Actor消息队列、事件缓存等
        }
    }
}
