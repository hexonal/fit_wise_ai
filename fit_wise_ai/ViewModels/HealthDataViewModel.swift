//
//  HealthDataViewModel.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation
import SwiftUI

/**
 * 健康数据视图模型
 * 
 * 作为 MVVM 架构中的 ViewModel 层，负责：
 * 1. 管理 UI 状态和数据绑定
 * 2. 协调 HealthKitService 和 AIService
 * 3. 处理用户交互逻辑
 * 4. 维护加载状态和错误处理
 * 
 * 注意：使用 @MainActor 确保所有 UI 更新在主线程执行
 */
@MainActor
class HealthDataViewModel: ObservableObject {
    /// HealthKit 数据服务实例
    @Published var healthKitService = HealthKitService()
    /// AI 建议服务实例
    @Published var aiService = AIService()
    /// 数据持久化服务实例
    @Published var persistenceService = DataPersistenceService()
    /// 网络服务实例
    @Published var networkService = NetworkService()
    /// 数据加载状态标识
    @Published var isLoading = false
    /// 权限拒绝提示框显示状态
    @Published var showingPermissionAlert = false
    
    /// 当前健康数据（计算属性）
    var healthData: HealthData {
        healthKitService.healthData
    }
    
    /// HealthKit 授权状态（计算属性）
    var isAuthorized: Bool {
        healthKitService.isAuthorized
    }
    
    /// AI 生成的建议列表（计算属性）
    var aiAdvice: [AIAdvice] {
        aiService.advice
    }
    
    /**
     * 请求 HealthKit 访问权限
     * 
     * 异步方法，处理权限请求流程：
     * 1. 调用 HealthKitService 请求授权
     * 2. 如果授权成功，自动刷新健康数据
     * 3. 如果授权失败，显示权限拒绝提示
     */
    func requestHealthKitPermission() async {
        await healthKitService.requestAuthorization()
        
        if healthKitService.isAuthorized {
            await refreshHealthData()
        } else {
            showingPermissionAlert = true
        }
    }
    
    /**
     * 刷新健康数据和 AI 建议
     * 
     * 主要的数据更新方法，执行以下步骤：
     * 1. 强制检查和请求权限
     * 2. 设置加载状态为 true
     * 3. 获取今日健康数据和7天历史数据
     * 4. 基于健康数据生成 AI 建议
     * 5. 重置加载状态为 false
     */
    func refreshHealthData() async {
        print("🟦 HealthDataViewModel: refreshHealthData 开始")
        
        // 始终先请求权限，确保授权状态是最新的
        print("🟦 HealthDataViewModel: 强制检查权限状态")
        await healthKitService.requestAuthorization()
        
        // 再次检查授权状态
        if !healthKitService.isAuthorized {
            print("🟠 HealthDataViewModel: 权限请求后仍未授权")
            showingPermissionAlert = true
            return
        }
        
        print("🟦 HealthDataViewModel: 已授权，开始加载数据")
        isLoading = true
        
        // 并发获取今日数据和历史数据
        print("🟦 HealthDataViewModel: 并发获取健康数据")
        async let todayData = healthKitService.fetchTodayHealthData()
        async let weeklyData = healthKitService.fetchWeeklyHealthData()
        
        // 等待所有数据获取完成
        await todayData
        await weeklyData
        
        // 保存健康数据到历史记录
        print("🟦 HealthDataViewModel: 保存健康数据")
        persistenceService.saveHealthData(healthKitService.healthData)
        
        // 生成AI建议（使用最新的健康数据）
        print("🟦 HealthDataViewModel: 生成AI建议")
        await aiService.generateAdvice(from: healthKitService.healthData)
        
        // 保存AI建议到历史记录
        print("🟦 HealthDataViewModel: 保存AI建议")
        persistenceService.saveAIAdvice(aiService.advice)
        
        isLoading = false
        print("🟦 HealthDataViewModel: refreshHealthData 完成，今日步数:\(healthKitService.healthData.steps)")
    }
    
    /**
     * 重新尝试权限请求
     * 
     * 提供给用户重新请求权限的入口
     * 通常在权限被拒绝后使用
     */
    func retryPermissionRequest() async {
        await requestHealthKitPermission()
    }
}