//
//  AIAdviceView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/14.
//

import SwiftUI

struct AIAdviceView: View {
    @StateObject private var aiService = AIService()
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var viewModel = HealthDataViewModel()
    
    @State private var isRefreshing = false
    @State private var selectedAdvice: AIAdvice?
    @State private var showHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 透明背景以显示渐变
                Color.clear
                
                if !healthKitService.isAuthorized {
                    // 现代化未授权提示
                    AIGradientCard(gradient: AITheme.primaryGradient) {
                        VStack(spacing: AISpacing.lg) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                            
                            Text("需要健康数据授权")
                                .font(AITypography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("请先在首页授权访问健康数据，才能获取个性化的AI建议")
                                .font(AITypography.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.9))
                            
                            AIPrimaryButton(
                                "前往授权",
                                icon: "heart.fill",
                                isLoading: isRefreshing
                            ) {
                                Task {
                                    await healthKitService.requestAuthorization()
                                    if healthKitService.isAuthorized {
                                        await loadData()
                                    }
                                }
                            }
                        }
                    }
                    .padding(AISpacing.md)
                    .navigationTitle("AI建议")
                } else {
                    ScrollView {
                        VStack(spacing: AISpacing.lg) {
                            // 现代化数据概览卡片
                            modernWeeklyDataSummary
                            
                            // 现代化AI建议区域
                            if aiService.isLoading {
                                AILoadingView(message: "正在生成个性化建议...")
                                    .padding(AISpacing.xl)
                            } else if aiService.advice.isEmpty {
                                modernEmptyAdviceView
                            } else {
                                modernAdviceSection
                            }
                        }
                        .padding(AISpacing.md)
                    }
                    .navigationTitle("AI建议")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showHistory = true
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(AITheme.accent)
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                Task {
                                    await refreshData()
                                }
                            } label: {
                                if isRefreshing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(AITheme.accent)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(AITheme.accent)
                                }
                            }
                            .disabled(isRefreshing)
                        }
                    }
                    .sheet(isPresented: $showHistory) {
                        AdviceHistoryView()
                    }
                    .task {
                        await loadData()
                    }
                }
            }
        }
    }
    
    // MARK: - 现代化Views
    
    private var modernWeeklyDataSummary: some View {
        AICard {
            VStack(alignment: .leading, spacing: AISpacing.md) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(AITheme.accent)
                    Text("近7天数据概览")
                        .font(AITypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AITheme.textPrimary)
                    Spacer()
                }
                
                if !healthKitService.weeklyHealthData.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AISpacing.md) {
                        AIStatsCard(
                            title: "平均步数",
                            value: String(format: "%.0f", averageSteps),
                            icon: "figure.walk",
                            color: AITheme.accent
                        )
                        
                        AIStatsCard(
                            title: "总消耗",
                            value: String(format: "%.0f", totalCalories),
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        AIStatsCard(
                            title: "运动时长",
                            value: String(format: "%.0f min", totalWorkoutMinutes),
                            icon: "timer",
                            color: .green
                        )
                    }
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: AISpacing.sm) {
                            ProgressView()
                                .tint(AITheme.accent)
                            Text("正在加载健康数据...")
                                .font(AITypography.caption)
                                .foregroundColor(AITheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AISpacing.lg)
                }
            }
        }
    }
    
    
    private var modernEmptyAdviceView: some View {
        AICard {
            VStack(spacing: AISpacing.lg) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 64))
                    .foregroundStyle(AITheme.primaryGradient)
                
                Text("暂无AI建议")
                    .font(AITypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                Text("点击下方按钮获取个性化健康建议")
                    .font(AITypography.body)
                    .foregroundColor(AITheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                AIPrimaryButton(
                    "生成AI建议",
                    icon: "sparkles",
                    isLoading: isRefreshing
                ) {
                    Task {
                        await refreshData()
                    }
                }
            }
            .padding(AISpacing.lg)
        }
    }
    
    private var modernAdviceSection: some View {
        VStack(alignment: .leading, spacing: AISpacing.lg) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(AITheme.primaryGradient)
                Text("个性化建议")
                    .font(AITypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                Spacer()
                Text("\(aiService.advice.count)条")
                    .font(AITypography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, AISpacing.sm)
                    .padding(.vertical, 4)
                    .background(AITheme.accent)
                    .cornerRadius(AIRadius.sm)
            }
            
            LazyVStack(spacing: AISpacing.md) {
                ForEach(aiService.advice) { advice in
                    ModernAdviceCard(advice: advice) {
                        selectedAdvice = advice
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageSteps: Double {
        let total = healthKitService.weeklyHealthData.reduce(0) { $0 + $1.steps }
        return healthKitService.weeklyHealthData.isEmpty ? 0 : Double(total) / Double(healthKitService.weeklyHealthData.count)
    }
    
    private var totalCalories: Double {
        healthKitService.weeklyHealthData.reduce(0) { $0 + $1.activeEnergyBurned }
    }
    
    private var totalWorkoutMinutes: Double {
        let totalSeconds = healthKitService.weeklyHealthData.reduce(0) { $0 + $1.workoutTime }
        return totalSeconds / 60
    }
    
    // MARK: - Methods
    
    private func loadData() async {
        // 只有在已授权的情况下才加载数据
        guard healthKitService.isAuthorized else { return }
        
        // 获取7天数据
        await healthKitService.fetchWeeklyHealthData()
        
        // 生成AI建议
        if !healthKitService.weeklyHealthData.isEmpty {
            // 使用最近一天的数据生成建议
            if let latestData = healthKitService.weeklyHealthData.last {
                await aiService.generateAdvice(from: latestData)
            }
        }
    }
    
    private func refreshData() async {
        guard healthKitService.isAuthorized else { return }
        
        isRefreshing = true
        await loadData()
        isRefreshing = false
    }
}

// MARK: - Modern AdviceCard Component

struct ModernAdviceCard: View {
    let advice: AIAdvice
    let onTap: () -> Void
    
    @State private var isCompleted = false
    @State private var isPressed = false
    
    var body: some View {
        AICard(padding: AISpacing.lg, isElevated: !isCompleted) {
            HStack(spacing: AISpacing.md) {
                // 现代化类别图标
                ZStack {
                    Circle()
                        .fill(categoryGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: categoryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // 建议内容
                VStack(alignment: .leading, spacing: AISpacing.xs) {
                    Text(advice.title)
                        .font(AITypography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompleted ? AITheme.textSecondary : AITheme.textPrimary)
                    
                    Text(advice.content)
                        .font(AITypography.body)
                        .foregroundColor(AITheme.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 现代化完成按钮
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isCompleted.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? AITheme.success : AITheme.surface)
                            .frame(width: 32, height: 32)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .stroke(AITheme.textSecondary, lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .opacity(isCompleted ? 0.7 : 1.0)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0) {
            // 长按开始
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
    
    private var categoryIcon: String {
        switch advice.category {
        case .exercise:
            return "figure.run"
        case .nutrition:
            return "leaf.fill"
        case .rest:
            return "moon.fill"
        case .general:
            return "star.fill"
        }
    }
    
    private var categoryColor: Color {
        switch advice.category {
        case .exercise:
            return AITheme.accent
        case .nutrition:
            return .green
        case .rest:
            return .purple
        case .general:
            return .orange
        }
    }
    
    private var categoryGradient: LinearGradient {
        switch advice.category {
        case .exercise:
            return AITheme.primaryGradient
        case .nutrition:
            return LinearGradient(colors: [.green, Color(red: 0.2, green: 0.8, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rest:
            return LinearGradient(colors: [.purple, Color(red: 0.6, green: 0.3, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .general:
            return LinearGradient(colors: [.orange, Color(red: 1.0, green: 0.7, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

#Preview {
    AIAdviceView()
}