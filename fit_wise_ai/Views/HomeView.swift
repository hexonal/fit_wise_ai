//
//  HomeView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

/**
 * 应用首页视图
 * 
 * 首页是用户的主要交互界面，负责：
 * 1. 健康数据授权管理
 * 2. 健康统计数据展示
 * 3. AI 个性化建议展示
 * 4. 下拉刷新功能
 * 
 * 视图会根据 HealthKit 授权状态显示不同内容：
 * - 未授权：显示权限请求界面
 * - 已授权：显示健康数据和 AI 建议
 */
struct HomeView: View {
    /// 健康数据视图模型，管理数据状态和业务逻辑
    @StateObject private var viewModel = HealthDataViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 根据授权状态显示不同内容
                    if !viewModel.isAuthorized {
                        // 显示权限请求视图
                        PermissionRequestView(viewModel: viewModel)
                    } else {
                        // 显示健康数据和 AI 建议
                        VStack(spacing: 20) {
                            // 健康统计数据展示
                            HealthStatsView(healthData: viewModel.healthData)
                            // AI 智能建议展示
                            AIAdviceView(advice: viewModel.aiAdvice, isLoading: viewModel.aiService.isLoading)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("健康概览")
            // 下拉刷新功能
            .refreshable {
                await viewModel.refreshHealthData()
            }
            // 视图加载时自动刷新数据
            .task {
                if viewModel.isAuthorized {
                    await viewModel.refreshHealthData()
                }
            }
            // 权限被拒绝时的提示对话框
            .alert("权限被拒绝", isPresented: $viewModel.showingPermissionAlert) {
                Button("设置") {
                    // 打开系统设置页面
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许访问健康数据以获取个性化建议")
            }
        }
    }
}

/**
 * 权限请求视图
 * 
 * 当用户尚未授权 HealthKit 访问权限时显示此视图
 * 提供友好的界面引导用户授权健康数据访问
 */
struct PermissionRequestView: View {
    /// 健康数据视图模型的引用
    let viewModel: HealthDataViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 心形图标，象征健康
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // 主标题
            Text("需要健康数据访问权限")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 说明文字
            Text("为了为您提供个性化的健身建议，我们需要读取您的健康数据")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // 授权按钮
            Button(action: {
                Task {
                    await viewModel.requestHealthKitPermission()
                }
            }) {
                Text("授权访问健康数据")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

/**
 * AI 建议展示视图
 * 
 * 负责展示基于用户健康数据生成的 AI 个性化建议
 * 支持加载状态、空状态和内容展示三种状态
 */
struct AIAdviceView: View {
    /// AI 建议数据数组
    let advice: [AIAdvice]
    /// 是否正在加载状态
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("AI 智能建议")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 根据状态显示不同内容
            if isLoading {
                // 加载状态
                HStack {
                    ProgressView()
                    Text("正在生成个性化建议...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if advice.isEmpty {
                // 空状态
                Text("暂无建议数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // 建议列表
                LazyVStack(spacing: 12) {
                    ForEach(advice) { adviceItem in
                        AIAdviceCard(advice: adviceItem)
                    }
                }
            }
        }
    }
}

/**
 * AI 建议卡片视图
 * 
 * 展示单条 AI 建议的卡片组件
 * 包含分类图标、标题和详细内容
 */
struct AIAdviceCard: View {
    /// 建议数据
    let advice: AIAdvice
    
    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            Image(systemName: advice.category.icon)
                .font(.title2)
                .foregroundColor(Color(advice.category.color))
                .frame(width: 32, height: 32)
            
            // 建议内容
            VStack(alignment: .leading, spacing: 4) {
                // 建议标题
                Text(advice.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // 建议详细内容
                Text(advice.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            // 边框颜色与分类颜色一致
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(advice.category.color).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}