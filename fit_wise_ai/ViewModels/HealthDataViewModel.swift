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
     * 1. 检查授权状态，未授权时请求权限
     * 2. 设置加载状态为 true
     * 3. 获取今日健康数据
     * 4. 基于健康数据生成 AI 建议
     * 5. 重置加载状态为 false
     */
    func refreshHealthData() async {
        guard healthKitService.isAuthorized else {
            await requestHealthKitPermission()
            return
        }
        
        isLoading = true
        
        await healthKitService.fetchTodayHealthData()
        await aiService.generateAdvice(from: healthKitService.healthData)
        
        isLoading = false
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