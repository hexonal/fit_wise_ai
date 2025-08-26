//
//  FutureAIAdviceView.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  革命性AI建议视图 - 完全重新设计
//

import SwiftUI

/// 2025未来感AI建议页 - 智能健康建议的革命性展示
struct FutureAIAdviceView: View {
    @StateObject private var aiService = AIService()
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var viewModel = HealthDataViewModel()
    
    // UI状态
    @State private var selectedCategory: AdviceCategory = .all
    @State private var isGenerating = false
    @State private var showingHistory = false
    @State private var animationPhase: Double = 0
    
    // 动画状态
    @State private var cardAppearance: [Bool] = Array(repeating: false, count: 10)
    @State private var pulseIntensity: Double = 0.5
    
    enum AdviceCategory: String, CaseIterable {
        case all = "全部"
        case exercise = "运动"
        case nutrition = "营养"
        case rest = "休息"
        case general = "综合"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear // 透明背景以显示主背景
                
                if !healthKitService.isAuthorized {
                    // 未授权状态
                    unauthorizedState
                } else {
                    // 主要内容
                    ScrollView {
                        LazyVStack(spacing: FluidSpacing.large) {
                            // AI助手头部
                            aiAssistantHeader
                            
                            // 健康数据概览
                            healthDataSummary
                            
                            // 类别选择器
                            categorySelector
                            
                            // AI建议内容
                            adviceContent
                        }
                        .padding(FluidSpacing.large)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHistory) {
                AdviceHistoryView()
            }
        }
        .task {
            await loadAIAdvice()
        }
        .onAppear {
            setupAnimations()
        }
    }
    
    // MARK: - AI助手头部
    
    private var aiAssistantHeader: some View {
        HStack(spacing: FluidSpacing.large) {
            // AI助手头像
            ZStack {
                // 外圈动画
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animationPhase * 360))
                
                // 内圈背景
                Circle()
                    .fill(FutureTheme.primaryGradient)
                    .frame(width: 70, height: 70)
                    .scaleEffect(1 + sin(animationPhase * 4) * 0.1)
                
                // AI图标
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(sin(animationPhase * 2) * 10))
            }
            
            // AI助手信息
            VStack(alignment: .leading, spacing: FluidSpacing.small) {
                Text("FitWise AI 助手")
                    .font(FutureTypography.heading2)
                    .fontWeight(.bold)
                    .foregroundColor(FutureTheme.textPrimary)
                
                Text(aiStatusText)
                    .font(FutureTypography.bodyMedium)
                    .foregroundColor(FutureTheme.textSecondary)
                    .opacity(0.7 + sin(animationPhase * 3) * 0.3)
                
                // AI状态指示器
                HStack(spacing: FluidSpacing.tiny) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseIntensity)
                    
                    Text("在线")
                        .font(FutureTypography.labelSmall)
                        .foregroundColor(Color.green)
                }
            }
            
            Spacer()
            
            // 历史记录按钮
            Button(action: { showingHistory = true }) {
                ZStack {
                    Circle()
                        .fill(FutureTheme.ultraGlass)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(FutureTheme.textAccent)
                }
            }
            .neonGlass()
        }
    }
    
    // MARK: - 健康数据概览
    
    private var healthDataSummary: some View {
        FutureCard(style: .neon) {
            VStack(spacing: FluidSpacing.large) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(FutureTheme.textAccent)
                    
                    Text("健康数据概览")
                        .font(FutureTypography.heading3)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    Spacer()
                    
                    FutureTag("最近7天", style: .glass)
                }
                
                if !healthKitService.weeklyHealthData.isEmpty {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 3),
                        spacing: FluidSpacing.medium
                    ) {
                        SummaryMetric(
                            title: "平均步数",
                            value: String(format: "%.0f", averageSteps),
                            icon: "figure.walk",
                            color: .blue,
                            trend: stepsTrend
                        )
                        
                        SummaryMetric(
                            title: "总消耗",
                            value: String(format: "%.0f", totalCalories),
                            icon: "flame.fill",
                            color: .orange,
                            trend: caloriesTrend
                        )
                        
                        SummaryMetric(
                            title: "运动时长",
                            value: String(format: "%.0f min", totalWorkoutMinutes),
                            icon: "timer",
                            color: .green,
                            trend: workoutTrend
                        )
                    }
                } else {
                    FutureLoadingView(
                        message: "正在分析健康数据...",
                        style: .neural
                    )
                }
            }
        }
    }
    
    // MARK: - 类别选择器
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FluidSpacing.medium) {
                ForEach(AdviceCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(FluidAnimation.bouncy) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, FluidSpacing.large)
        }
    }
    
    // MARK: - AI建议内容
    
    private var adviceContent: some View {
        VStack(alignment: .leading, spacing: FluidSpacing.large) {
            // 标题和生成按钮
            HStack {
                Text("个性化建议")
                    .font(FutureTypography.heading3)
                    .fontWeight(.bold)
                    .foregroundColor(FutureTheme.textPrimary)
                
                Spacer()
                
                if !isGenerating && !filteredAdvice.isEmpty {
                    FutureTag("\(filteredAdvice.count)条建议", style: .neon(.cyan))
                }
            }
            
            if isGenerating {
                // AI生成状态
                aiGeneratingState
            } else if filteredAdvice.isEmpty {
                // 空状态
                emptyAdviceState
            } else {
                // 建议列表
                adviceList
            }
        }
    }
    
    // MARK: - AI生成状态
    
    private var aiGeneratingState: some View {
        FutureCard(style: .holographic) {
            VStack(spacing: FluidSpacing.xxxlarge) {
                // AI思考动画
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.6), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(40 + index * 20))
                            .rotationEffect(.degrees(animationPhase * 120 * (1 + Double(index) * 0.5)))
                    }
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(FutureTheme.primaryGradient)
                        .scaleEffect(1 + sin(animationPhase * 4) * 0.2)
                }
                
                VStack(spacing: FluidSpacing.large) {
                    Text("AI正在分析您的健康数据")
                        .font(FutureTypography.heading3)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    Text("基于您的健康状况、运动习惯和目标，生成个性化建议...")
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: FluidSpacing.small) {
                        ForEach(["分析数据", "识别模式", "生成建议"], id: \.self) { step in
                            FutureTag(step, style: .glass)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 空建议状态
    
    private var emptyAdviceState: some View {
        FutureEmptyState(
            icon: "lightbulb.fill",
            title: "暂无AI建议",
            subtitle: "点击下方按钮，让AI根据您的健康数据生成个性化建议",
            actionTitle: "生成AI建议"
        ) {
            Task {
                await generateAdvice()
            }
        }
    }
    
    // MARK: - 建议列表
    
    private var adviceList: some View {
        LazyVStack(spacing: FluidSpacing.large) {
            ForEach(Array(filteredAdvice.enumerated()), id: \.element.id) { index, advice in
                FutureAdviceCard(
                    advice: advice,
                    appearanceIndex: index
                )
                .opacity(cardAppearance.indices.contains(index) ? (cardAppearance[index] ? 1 : 0) : 1)
                .offset(y: cardAppearance.indices.contains(index) ? (cardAppearance[index] ? 0 : 50) : 0)
                .onAppear {
                    if cardAppearance.indices.contains(index) {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.2)) {
                            cardAppearance[index] = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 未授权状态
    
    private var unauthorizedState: some View {
        FutureCard(style: .holographic) {
            VStack(spacing: FluidSpacing.xxxlarge) {
                // 锁定图标动画
                ZStack {
                    Circle()
                        .fill(FutureTheme.primaryGradient)
                        .frame(width: 100, height: 100)
                        .blur(radius: 30)
                        .opacity(0.6)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(sin(animationPhase * 2) * 5))
                }
                
                VStack(spacing: FluidSpacing.large) {
                    Text("需要健康数据授权")
                        .font(FutureTypography.heading2)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    Text("请先在首页授权访问健康数据，AI助手将为您提供基于真实数据的个性化建议")
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    FuturePrimaryButton(
                        "前往授权",
                        icon: "heart.fill",
                        style: .gradient
                    ) {
                        Task {
                            await healthKitService.requestAuthorization()
                            if healthKitService.isAuthorized {
                                await loadAIAdvice()
                            }
                        }
                    }
                }
            }
        }
        .padding(FluidSpacing.large)
    }
    
    // MARK: - 计算属性
    
    private var aiStatusText: String {
        if isGenerating {
            return "正在思考中..."
        } else if !healthKitService.isAuthorized {
            return "等待数据授权"
        } else if filteredAdvice.isEmpty {
            return "准备生成建议"
        } else {
            return "已为您准备了\(filteredAdvice.count)条建议"
        }
    }
    
    private var filteredAdvice: [AIAdvice] {
        if selectedCategory == .all {
            return aiService.advice
        } else {
            return aiService.advice.filter { advice in
                switch selectedCategory {
                case .exercise: return advice.category == .exercise
                case .nutrition: return advice.category == .nutrition  
                case .rest: return advice.category == .rest
                case .general: return advice.category == .general
                default: return true
                }
            }
        }
    }
    
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
    
    private var stepsTrend: String {
        averageSteps > 8000 ? "+15%" : "-8%"
    }
    
    private var caloriesTrend: String {
        totalCalories > 2000 ? "+12%" : "-5%"
    }
    
    private var workoutTrend: String {
        totalWorkoutMinutes > 150 ? "+20%" : "-10%"
    }
    
    // MARK: - 业务逻辑
    
    private func loadAIAdvice() async {
        guard healthKitService.isAuthorized else { return }
        
        await healthKitService.fetchWeeklyHealthData()
        
        if !healthKitService.weeklyHealthData.isEmpty {
            if let latestData = healthKitService.weeklyHealthData.last {
                await aiService.generateAdvice(from: latestData)
            }
        }
    }
    
    private func generateAdvice() async {
        guard healthKitService.isAuthorized else { return }
        
        isGenerating = true
        
        // 模拟AI生成过程
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
        
        await loadAIAdvice()
        
        isGenerating = false
        
        // 触发卡片出现动画
        for i in 0..<min(cardAppearance.count, filteredAdvice.count) {
            cardAppearance[i] = false
        }
    }
    
    private func setupAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            animationPhase = 1
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseIntensity = 1.5
        }
    }
}

// MARK: - 辅助组件

/// 数据概览指标
struct SummaryMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(spacing: FluidSpacing.small) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(FutureTypography.labelLarge)
                .fontWeight(.bold)
                .foregroundColor(FutureTheme.textPrimary)
            
            Text(title)
                .font(FutureTypography.micro)
                .foregroundColor(FutureTheme.textSecondary)
            
            FutureTag(trend, style: .glass)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 类别按钮
struct CategoryButton: View {
    let category: FutureAIAdviceView.AdviceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(FutureTypography.labelMedium)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : FutureTheme.textSecondary)
                .padding(.horizontal, FluidSpacing.large)
                .padding(.vertical, FluidSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: FluidRadius.button)
                        .fill(
                            isSelected ?
                            AnyShapeStyle(FutureTheme.primaryGradient) :
                            AnyShapeStyle(FutureTheme.ultraGlass)
                        )
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(FluidAnimation.spring, value: isSelected)
    }
}

/// 未来感建议卡片
struct FutureAdviceCard: View {
    let advice: AIAdvice
    let appearanceIndex: Int
    
    @State private var isCompleted = false
    @State private var isExpanded = false
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        FutureCard(style: cardStyle, isInteractive: true) {
            AnyView(VStack(spacing: FluidSpacing.large) {
                // 顶部：类别和完成状态
                HStack {
                    // 类别图标
                    ZStack {
                        Circle()
                            .fill(categoryGradient)
                            .frame(width: 50, height: 50)
                            .blur(radius: glowIntensity * 10)
                            .opacity(0.6)
                        
                        Circle()
                            .fill(categoryGradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 完成按钮
                    Button(action: {
                        withAnimation(FluidAnimation.bouncy) {
                            isCompleted.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .stroke(FutureTheme.textSecondary, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                
                // 中部：建议内容
                VStack(alignment: .leading, spacing: FluidSpacing.medium) {
                    Text(advice.title)
                        .font(FutureTypography.heading4)
                        .fontWeight(.bold)
                        .foregroundColor(isCompleted ? FutureTheme.textSecondary : FutureTheme.textPrimary)
                    
                    Text(advice.content)
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                        .lineLimit(isExpanded ? nil : 3)
                        .multilineTextAlignment(.leading)
                    
                    if advice.content.count > 100 {
                        Button(action: {
                            withAnimation(FluidAnimation.gentle) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "收起" : "展开")
                                .font(FutureTypography.labelSmall)
                                .foregroundColor(FutureTheme.textAccent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
        .opacity(isCompleted ? 0.7 : 1.0)
        .scaleEffect(isCompleted ? 0.98 : 1.0)
        .animation(FluidAnimation.spring, value: isCompleted)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(appearanceIndex) * 0.5)) {
                glowIntensity = 0.8
            }
        }
    }
    
    private var cardStyle: FutureCard<AnyView>.Style {
        switch advice.category {
        case .exercise: return .neon
        case .nutrition: return .glass
        case .rest: return .holographic
        case .general: return .floating
        }
    }
    
    private var categoryIcon: String {
        switch advice.category {
        case .exercise: return "figure.run"
        case .nutrition: return "leaf.fill"
        case .rest: return "moon.fill"
        case .general: return "star.fill"
        }
    }
    
    private var categoryGradient: LinearGradient {
        switch advice.category {
        case .exercise: return LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .nutrition: return LinearGradient(colors: [Color.green, Color.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rest: return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .general: return LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

#Preview {
    FutureAIAdviceView()
        .environmentObject(HealthKitService())
}