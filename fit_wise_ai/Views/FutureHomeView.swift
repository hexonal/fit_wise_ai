//
//  FutureHomeView.swift
//  fit_wise_ai
//
//  Created by Claude on 2025/8/26.
//  革命性首页视图 - 完全重新设计
//

import SwiftUI
import HealthKit
import Charts

/// 2025未来感首页 - 健康数据的革命性展示
struct FutureHomeView: View {
    @StateObject private var viewModel = HealthDataViewModel()
    @EnvironmentObject var healthKitService: HealthKitService
    
    // UI状态
    @State private var selectedMetric = 0
    @State private var isCheckingPermissions = true
    @State private var missingPermissions: [HKObjectType] = []
    @State private var showingDetailView = false
    @State private var animationPhase: Double = 0
    
    // 动画状态
    @State private var cardOffsets: [CGFloat] = [0, 0, 0, 0]
    @State private var dataAnimationTrigger = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear // 透明背景以显示主背景
                
                if isCheckingPermissions {
                    // 未来感权限检查界面
                    revolutionaryPermissionCheck
                } else {
                    ScrollView {
                        LazyVStack(spacing: FluidSpacing.large) {
                            if !missingPermissions.isEmpty {
                                // 权限请求界面
                                futurePermissionRequest
                            } else if healthKitService.isAuthorized {
                                // 主要内容区域
                                mainContentArea
                            } else {
                                // 初始授权界面
                                initialAuthorizationView
                            }
                        }
                        .padding(FluidSpacing.large)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await checkPermissionsAndRefreshData()
            }
        }
        .task {
            await checkPermissionsAndRefreshData()
        }
        .onAppear {
            setupAnimations()
        }
    }
    
    // MARK: - 革命性权限检查界面
    
    private var revolutionaryPermissionCheck: some View {
        VStack(spacing: FluidSpacing.xxxlarge) {
            Spacer()
            
            // 全息扫描效果
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(animationPhase * 360))
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.clear],
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-animationPhase * 240))
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(FutureTheme.primaryGradient)
                    .scaleEffect(1 + sin(animationPhase * 4) * 0.1)
            }
            
            FutureLoadingView(
                message: "正在初始化健康数据系统...",
                style: .quantum
            )
            
            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - 主要内容区域
    
    private var mainContentArea: some View {
        LazyVStack(spacing: FluidSpacing.large) {
            // 顶部问候和日期
            futureDateHeader
            
            // 今日健康概览
            todayHealthOverview
            
            // 趋势图表区域
            if !healthKitService.weeklyHealthData.isEmpty {
                trendChartsArea
                
                // 详细数据列表
                weeklyDataSection
            } else {
                noDataAvailable
            }
        }
    }
    
    // MARK: - 未来感日期头部
    
    private var futureDateHeader: some View {
        VStack(spacing: FluidSpacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: FluidSpacing.tiny) {
                    Text("健康概览")
                        .font(FutureTypography.displayMD)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FutureTheme.textAccent, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(currentDateString)
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                }
                
                Spacer()
                
                // 健康评分指示器
                ZStack {
                    Circle()
                        .stroke(FutureTheme.ultraGlassStroke, lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: healthScorePercentage)
                        .stroke(FutureTheme.healthExcellent, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(healthScorePercentage * 100))")
                            .font(FutureTypography.labelLarge)
                            .fontWeight(.bold)
                            .foregroundColor(FutureTheme.textPrimary)
                        
                        Text("分")
                            .font(FutureTypography.micro)
                            .foregroundColor(FutureTheme.textSecondary)
                    }
                }
                .onTapGesture {
                    showingDetailView = true
                }
            }
        }
        .animation(.easeInOut(duration: 2), value: dataAnimationTrigger)
    }
    
    // MARK: - 今日健康概览
    
    private var todayHealthOverview: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: FluidSpacing.medium), count: 2),
            spacing: FluidSpacing.medium
        ) {
            FutureHealthCard(
                title: "今日步数",
                value: String(viewModel.healthData.steps),
                unit: "步",
                icon: "figure.walk",
                healthStatus: stepHealthStatus,
                trend: stepTrend,
                isAnimated: true
            )
            .offset(y: cardOffsets[0])
            
            FutureHealthCard(
                title: "活动消耗",
                value: String(format: "%.0f", viewModel.healthData.activeEnergyBurned),
                unit: "千卡",
                icon: "flame.fill",
                healthStatus: .good,
                trend: .init(percentage: 8.5, isPositive: true, description: "比昨天高"),
                isAnimated: true
            )
            .offset(y: cardOffsets[1])
            
            FutureHealthCard(
                title: "运动时长",
                value: String(format: "%.0f", viewModel.healthData.workoutTime / 60),
                unit: "分钟",
                icon: "timer",
                healthStatus: workoutHealthStatus,
                isAnimated: true
            )
            .offset(y: cardOffsets[2])
            
            if let heartRate = viewModel.healthData.heartRate {
                FutureHealthCard(
                    title: "心率",
                    value: String(format: "%.0f", heartRate),
                    unit: "BPM",
                    icon: "heart.fill",
                    healthStatus: heartRateHealthStatus,
                    trend: .init(percentage: 2.3, isPositive: false, description: "静息心率下降"),
                    isAnimated: true
                )
                .offset(y: cardOffsets[3])
            }
        }
    }
    
    // MARK: - 趋势图表区域
    
    private var trendChartsArea: some View {
        FutureCard(style: .neon) {
            trendChartsContent
        }
    }
    
    private var trendChartsContent: some View {
        VStack(spacing: FluidSpacing.large) {
                // 标题和指标选择器
                HStack {
                    Text("7天趋势分析")
                        .font(FutureTypography.heading3)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    Spacer()
                    
                    FutureTag("实时数据", style: .neon(.cyan))
                }
                
                // 自定义指标选择器
                HStack(spacing: FluidSpacing.small) {
                    ForEach(0..<3) { index in
                        Button(action: {
                            withAnimation(FluidAnimation.bouncy) {
                                selectedMetric = index
                            }
                        }) {
                            Text(metricNames[index])
                                .font(FutureTypography.labelMedium)
                                .fontWeight(.medium)
                                .foregroundColor(selectedMetric == index ? .white : FutureTheme.textSecondary)
                                .padding(.horizontal, FluidSpacing.medium)
                                .padding(.vertical, FluidSpacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: FluidRadius.button)
                                        .fill(
                                            selectedMetric == index ?
                                            AnyShapeStyle(FutureTheme.primaryGradient) :
                                            AnyShapeStyle(FutureTheme.ultraGlass)
                                        )
                                )
                        }
                    }
                    
                    Spacer()
                }
                
                // 未来感图表
                Chart(healthKitService.weeklyHealthData) { data in
                    switch selectedMetric {
                    case 0: // 步数
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("步数", data.steps)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(60)
                        
                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("步数", data.steps)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                    case 1: // 卡路里
                        BarMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("卡路里", data.activeEnergyBurned)
                        )
                        .foregroundStyle(FutureTheme.healthWarning)
                        .cornerRadius(FluidRadius.sm)
                        
                    case 2: // 运动时长
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("分钟", data.workoutTime / 60)
                        )
                        .foregroundStyle(FutureTheme.healthExcellent)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                    default:
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("数据", 0)
                        )
                        .opacity(0)
                    }
                }
                .frame(height: 200)
                .chartBackground { _ in
                    Rectangle()
                        .fill(Color.clear)
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                FutureTheme.ultraGlass
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
        }
    }
    
    // MARK: - 周数据详情
    
    private var weeklyDataSection: some View {
        VStack(alignment: .leading, spacing: FluidSpacing.large) {
            HStack {
                Text("详细数据")
                    .font(FutureTypography.heading3)
                    .fontWeight(.bold)
                    .foregroundColor(FutureTheme.textPrimary)
                
                Spacer()
                
                Button("查看全部") {
                    // 导航到详细页面
                }
                .font(FutureTypography.labelMedium)
                .foregroundColor(FutureTheme.textAccent)
            }
            
            LazyVStack(spacing: FluidSpacing.medium) {
                ForEach(Array(healthKitService.weeklyHealthData.suffix(3).enumerated()), id: \.element.id) { index, data in
                    WeeklyDataRow(data: data, isToday: Calendar.current.isDateInToday(data.date))
                        .offset(y: cardOffsets.indices.contains(index) ? cardOffsets[index] * 0.5 : 0)
                }
            }
        }
    }
    
    // MARK: - 无数据状态
    
    private var noDataAvailable: some View {
        FutureEmptyState(
            icon: "chart.line.uptrend.xyaxis",
            title: "暂无健康数据",
            subtitle: "开始使用设备记录您的健康数据，或手动添加健康记录以获取个性化的AI分析",
            actionTitle: "获取健康建议"
        ) {
            // 导航到AI建议页面
        }
    }
    
    // MARK: - 权限相关视图
    
    private var futurePermissionRequest: some View {
        FutureCard(style: .holographic) {
            VStack(spacing: FluidSpacing.xxxlarge) {
                // 全息权限图标
                ZStack {
                    Circle()
                        .fill(FutureTheme.primaryGradient)
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .opacity(0.8)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: FluidSpacing.large) {
                    Text("需要健康数据权限")
                        .font(FutureTypography.heading2)
                        .fontWeight(.bold)
                        .foregroundColor(FutureTheme.textPrimary)
                    
                    Text("为了提供最准确的AI健康分析，我们需要访问以下健康数据")
                        .font(FutureTypography.bodyMedium)
                        .foregroundColor(FutureTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: FluidSpacing.medium) {
                        ForEach(Array(missingPermissions.enumerated()), id: \.offset) { _, permission in
                            HStack(spacing: FluidSpacing.medium) {
                                Image(systemName: permissionIcon(for: permission))
                                    .font(.title3)
                                    .foregroundColor(FutureTheme.textAccent)
                                    .frame(width: 24)
                                
                                Text(permissionName(for: permission))
                                    .font(FutureTypography.bodyMedium)
                                    .foregroundColor(FutureTheme.textPrimary)
                            }
                        }
                    }
                    
                    FuturePrimaryButton(
                        "授权健康数据",
                        icon: "heart.fill",
                        style: .holographic
                    ) {
                        Task {
                            await healthKitService.requestAuthorization()
                            await checkPermissionsAndRefreshData()
                        }
                    }
                }
            }
        }
    }
    
    private var initialAuthorizationView: some View {
        FutureCard(style: .glass) {
            VStack(spacing: FluidSpacing.xxxlarge) {
                // 欢迎动画
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                FutureTheme.primaryGradient,
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(60 + index * 20))
                            .scaleEffect(1 + sin(animationPhase * 2 + Double(index)) * 0.1)
                    }
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(FutureTheme.primaryGradient)
                }
                
                VStack(spacing: FluidSpacing.large) {
                    Text("欢迎使用 FitWise AI")
                        .font(FutureTypography.displaySM)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FutureTheme.textAccent, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("开启您的智能健康管理之旅")
                        .font(FutureTypography.bodyLarge)
                        .foregroundColor(FutureTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    FuturePrimaryButton(
                        "开始体验",
                        icon: "arrow.right.circle.fill",
                        size: .large,
                        style: .gradient
                    ) {
                        Task {
                            await healthKitService.requestAuthorization()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助计算属性
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
    
    private var healthScorePercentage: Double {
        let steps = Double(viewModel.healthData.steps)
        let calories = viewModel.healthData.activeEnergyBurned
        let workout = viewModel.healthData.workoutTime / 60
        
        let stepScore = min(steps / 10000, 1.0) * 0.4
        let calorieScore = min(calories / 400, 1.0) * 0.3
        let workoutScore = min(workout / 30, 1.0) * 0.3
        
        return stepScore + calorieScore + workoutScore
    }
    
    private var stepHealthStatus: FutureHealthCard.HealthStatus {
        return viewModel.healthData.steps >= 10000 ? .excellent :
               viewModel.healthData.steps >= 7500 ? .good :
               viewModel.healthData.steps >= 5000 ? .warning : .critical
    }
    
    private var workoutHealthStatus: FutureHealthCard.HealthStatus {
        let minutes = viewModel.healthData.workoutTime / 60
        return minutes >= 30 ? .excellent :
               minutes >= 20 ? .good :
               minutes >= 10 ? .warning : .critical
    }
    
    private var heartRateHealthStatus: FutureHealthCard.HealthStatus {
        guard let hr = viewModel.healthData.heartRate else { return .good }
        return hr >= 60 && hr <= 100 ? .excellent :
               hr >= 50 && hr <= 110 ? .good : .warning
    }
    
    private var stepTrend: FutureHealthCard.TrendData? {
        return .init(
            percentage: 12.5,
            isPositive: true,
            description: "接近目标"
        )
    }
    
    private var metricNames: [String] {
        ["步数", "卡路里", "运动"]
    }
    
    // MARK: - 权限辅助方法
    
    private func permissionIcon(for permission: HKObjectType) -> String {
        if permission == HKQuantityType.quantityType(forIdentifier: .stepCount) {
            return "figure.walk"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .heartRate) {
            return "heart.fill"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            return "flame.fill"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            return "location.fill"
        }
        return "health"
    }
    
    private func permissionName(for permission: HKObjectType) -> String {
        if permission == HKQuantityType.quantityType(forIdentifier: .stepCount) {
            return "步数数据"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .heartRate) {
            return "心率数据"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            return "活动消耗"
        } else if permission == HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            return "步行距离"
        }
        return "健康数据"
    }
    
    // MARK: - 业务逻辑方法
    
    private func checkPermissionsAndRefreshData() async {
        isCheckingPermissions = true
        
        await healthKitService.checkCurrentAuthorizationStatus()
        
        let requiredTypes: [HKObjectType] = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        missingPermissions = requiredTypes.filter { type in
            healthKitService.healthStore.authorizationStatus(for: type) != .sharingAuthorized
        }
        
        if healthKitService.isAuthorized && missingPermissions.isEmpty {
            await viewModel.refreshHealthData()
            await healthKitService.fetchTodayHealthData()
            await healthKitService.fetchWeeklyHealthData()
            
            // 触发数据动画
            withAnimation(.easeInOut(duration: 1.5)) {
                dataAnimationTrigger.toggle()
            }
        }
        
        isCheckingPermissions = false
    }
    
    private func setupAnimations() {
        // 卡片入场动画
        for i in 0..<4 {
            cardOffsets[i] = 50
        }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(0) * 0.1)) {
            cardOffsets[0] = 0
        }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(1) * 0.1)) {
            cardOffsets[1] = 0
        }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(2) * 0.1)) {
            cardOffsets[2] = 0
        }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(3) * 0.1)) {
            cardOffsets[3] = 0
        }
    }
}

// MARK: - 周数据行组件

struct WeeklyDataRow: View {
    let data: HealthData
    let isToday: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }
    
    var body: some View {
        FutureCard(style: .glass) {
            HStack(spacing: FluidSpacing.large) {
                // 日期指示器
                VStack(spacing: FluidSpacing.tiny) {
                    Text(dateFormatter.string(from: data.date))
                        .font(FutureTypography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(isToday ? FutureTheme.textAccent : FutureTheme.textPrimary)
                    
                    if isToday {
                        FutureTag("今天", style: .neon(.cyan))
                    }
                }
                .frame(width: 60, alignment: .leading)
                
                // 数据指标
                HStack(spacing: FluidSpacing.large) {
                    DataMetric(
                        icon: "figure.walk",
                        value: String(data.steps),
                        color: .blue
                    )
                    
                    DataMetric(
                        icon: "flame.fill",
                        value: String(format: "%.0f", data.activeEnergyBurned),
                        color: .orange
                    )
                    
                    DataMetric(
                        icon: "timer",
                        value: String(format: "%.0f", data.workoutTime / 60),
                        color: .green
                    )
                }
                
                Spacer()
                
                // 达标指示器
                if data.steps >= 10000 {
                    ZStack {
                        Circle()
                            .fill(FutureTheme.healthExcellent)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct DataMetric: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: FluidSpacing.tiny) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(FutureTypography.labelSmall)
                .foregroundColor(FutureTheme.textSecondary)
        }
    }
}

#Preview {
    FutureHomeView()
        .environmentObject(HealthKitService())
}