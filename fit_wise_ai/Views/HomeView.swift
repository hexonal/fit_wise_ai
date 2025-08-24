//
//  HomeView.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import SwiftUI
import HealthKit
import Charts

/**
 * 主页视图 - 健康数据概览
 * 
 * 功能包括：
 * 1. HealthKit权限检查和请求
 * 2. 今日健康数据展示（步数、心率、活动消耗等）
 * 3. 7天健康数据趋势图表
 * 4. 自适应布局支持（iPhone SE到iPad）
 * 5. 下拉刷新功能
 */
struct HomeView: View {
    /// 健康数据视图模型，管理数据状态和业务逻辑
    @StateObject private var viewModel = HealthDataViewModel()
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTab = 0
    /// 是否正在检查权限状态的标识，用于显示加载界面
    @State private var isCheckingPermissions = true
    /// 缺失的HealthKit权限列表，用于显示具体需要哪些权限
    @State private var missingPermissions: [HKObjectType] = []
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // 透明背景以显示渐变
                    Color.clear
                    
                    if isCheckingPermissions {
                        // 现代化权限检查加载界面
                        AILoadingView(message: "正在检查健康数据权限...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: adaptiveSpacing(for: geometry)) {
                                // 根据权限状态显示不同内容
                                if !missingPermissions.isEmpty {
                                    // 权限请求视图
                                    SimplePermissionRequestView(
                                        missingPermissions: missingPermissions
                                    ) {
                                        await checkPermissionsAndRefreshData()
                                    }
                                } else if healthKitService.isAuthorized {
                                    // 现代化的健康数据展示（自适应布局）
                                    VStack(spacing: adaptiveSpacing(for: geometry)) {
                                        // 今日健康统计数据展示（自适应网格）
                                        AdaptiveHealthStatsView(
                                            healthData: viewModel.healthData, 
                                            geometry: geometry
                                        )
                                        
                                        // 7天数据趋势图表（自适应高度）
                                        if !healthKitService.weeklyHealthData.isEmpty {
                                            AdaptiveWeeklyChartsView(
                                                weeklyData: healthKitService.weeklyHealthData, 
                                                selectedTab: $selectedTab,
                                                geometry: geometry
                                            )
                                            
                                            // 数据详情列表（根据屏幕大小自适应显示）
                                            if !isCompactLayout(for: geometry) {
                                                // 非紧凑布局显示完整的数据列表
                                                FullWeeklyDataView(weeklyData: healthKitService.weeklyHealthData)
                                            } else {
                                                // 紧凑布局时显示简化版本
                                                CompactWeeklyDataView(weeklyData: healthKitService.weeklyHealthData, geometry: geometry)
                                            }
                                        } else {
                                            // 无数据时显示提示
                                            NoDataView()
                                        }
                                    }
                                } else {
                                    // 初始权限请求视图
                                    InitialPermissionView()
                                }
                            }
                            .padding(adaptivePadding(for: geometry))
                        }
                    }
                }
                .navigationTitle("健康概览")
                .navigationBarTitleDisplayMode(.large)
                // 下拉刷新功能
                .refreshable {
                    await checkPermissionsAndRefreshData()
                }
            }
        }
        // 视图首次加载时检查权限
        .task {
            await checkPermissionsAndRefreshData()
        }
        // 权限被拒绝时的提示对话框
        .alert("健康数据访问被拒绝", isPresented: $viewModel.showingPermissionAlert) {
            Button("重新授权") {
                Task {
                    await healthKitService.requestAuthorization()
                    await checkPermissionsAndRefreshData()
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要访问您的健康数据以提供个性化建议。请在系统权限对话框中选择\"允许\"。")
        }
    }
    
    // MARK: - Private Methods
    
    /// 检查HealthKit权限状态并刷新健康数据
    private func checkPermissionsAndRefreshData() async {
        print("🔵 HomeView: 开始权限检查流程")
        isCheckingPermissions = true
        
        // 首先检查当前授权状态
        await healthKitService.checkCurrentAuthorizationStatus()
        print("🔵 HomeView: 权限检查完成，isAuthorized: \(healthKitService.isAuthorized)")
        
        // 检查应用必需的HealthKit权限，返回缺失的权限类型
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
            print("🔵 HomeView: 权限完整，开始刷新健康数据")
            await viewModel.refreshHealthData()
            await healthKitService.fetchTodayHealthData()
            await healthKitService.fetchWeeklyHealthData()
            print("🔵 HomeView: 健康数据刷新完成")
        } else {
            print("🔵 HomeView: 权限不完整，将显示权限请求界面")
        }
        
        // 权限检查完成，更新UI状态
        isCheckingPermissions = false
    }
    
    // MARK: - 自适应布局辅助函数
    
    /// 根据屏幕大小计算自适应间距
    private func adaptiveSpacing(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let isCompact = screenWidth < 400 || screenHeight < 700
        let isRegular = screenWidth > 600
        
        if isCompact {
            return AISpacing.sm
        } else if isRegular {
            return AISpacing.xl
        } else {
            return AISpacing.lg
        }
    }
    
    /// 根据屏幕大小判断是否为紧凑布局
    private func isCompactLayout(for geometry: GeometryProxy) -> Bool {
        return geometry.size.width < 400 || geometry.size.height < 700
    }
    
    /// 根据屏幕大小计算自适应内边距
    private func adaptivePadding(for geometry: GeometryProxy) -> EdgeInsets {
        let screenWidth = geometry.size.width
        
        if screenWidth < 400 {
            return EdgeInsets(top: AISpacing.sm, leading: AISpacing.sm, bottom: AISpacing.sm, trailing: AISpacing.sm)
        } else if screenWidth > 600 {
            return EdgeInsets(top: AISpacing.lg, leading: AISpacing.xl, bottom: AISpacing.lg, trailing: AISpacing.xl)
        } else {
            return EdgeInsets(top: AISpacing.md, leading: AISpacing.md, bottom: AISpacing.md, trailing: AISpacing.md)
        }
    }
    
}

// MARK: - 自适应组件

/**
 * 自适应健康统计视图
 */
struct AdaptiveHealthStatsView: View {
    let healthData: HealthData
    let geometry: GeometryProxy
    
    /// 根据屏幕大小计算自适应列数
    private var adaptiveColumns: [GridItem] {
        let screenWidth = geometry.size.width
        let isLandscape = geometry.size.width > geometry.size.height
        let minColumnWidth: CGFloat = 140
        let padding: CGFloat = 32
        let spacing: CGFloat = 12
        let availableWidth = screenWidth - padding
        let maxColumns = max(1, Int(availableWidth / (minColumnWidth + spacing)))
        
        let finalColumns: Int
        if screenWidth < 400 {  // iPhone SE等小屏幕
            finalColumns = isLandscape ? min(3, maxColumns) : 2
        } else if screenWidth > 600 {  // iPad等大屏幕
            finalColumns = isLandscape ? min(5, maxColumns) : min(3, maxColumns)
        } else {  // 标准iPhone
            finalColumns = isLandscape ? min(4, maxColumns) : 2
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: finalColumns)
    }
    
    /// 自适应间距
    private var adaptiveSpacing: CGFloat {
        let screenWidth = geometry.size.width
        if screenWidth < 400 {
            return AISpacing.xs
        } else if screenWidth > 600 {
            return AISpacing.lg
        } else {
            return AISpacing.sm
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            HStack {
                Text("今日概览")
                    .font(geometry.size.width < 400 ? AITypography.headline : AITypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                Spacer()
                
                Text(DateFormatter.shortDate.string(from: healthData.date))
                    .font(AITypography.caption)
                    .foregroundColor(AITheme.textSecondary)
            }
            
            LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                AIStatsCard(
                    title: "步数",
                    value: "\(healthData.steps)",
                    icon: "figure.walk",
                    color: AITheme.accent,
                    trend: healthData.steps >= 10000 ? "达标" : nil,
                    isPositiveTrend: healthData.steps >= 10000
                )
                
                AIStatsCard(
                    title: "活动消耗",
                    value: String(format: "%.0f", healthData.activeEnergyBurned),
                    icon: "flame.fill",
                    color: .orange
                )
                
                AIStatsCard(
                    title: "运动时长",
                    value: String(format: "%.0f", healthData.workoutTime / 60),
                    icon: "timer",
                    color: .green
                )
                
                if let heartRate = healthData.heartRate {
                    AIStatsCard(
                        title: "心率",
                        value: String(format: "%.0f", heartRate),
                        icon: "heart.fill",
                        color: .red
                    )
                }
            }
        }
    }
}

/**
 * 自适应周数据图表视图
 */
struct AdaptiveWeeklyChartsView: View {
    let weeklyData: [HealthData]
    @Binding var selectedTab: Int
    let geometry: GeometryProxy
    
    /// 自适应图表高度
    private var adaptiveChartHeight: CGFloat {
        let screenHeight = geometry.size.height
        let screenWidth = geometry.size.width
        let isLandscape = screenWidth > screenHeight
        let baseRatio: CGFloat = isLandscape ? 0.25 : 0.22
        let calculatedHeight = screenHeight * baseRatio
        let minHeight: CGFloat = 150
        let maxHeight: CGFloat = 300
        return max(minHeight, min(maxHeight, calculatedHeight))
    }
    
    /// 自适应间距
    private var adaptiveSpacing: CGFloat {
        geometry.size.width < 400 ? AISpacing.sm : AISpacing.lg
    }
    
    /// 自适应字体大小
    private var adaptiveTitleFont: Font {
        geometry.size.width < 400 ? AITypography.headline : AITypography.title2
    }
    
    private var chineseWeekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = geometry.size.width < 400 ? "E" : "EEE"
        return formatter
    }
    
    var body: some View {
        AICard {
            VStack(alignment: .leading, spacing: adaptiveSpacing) {
                Text("7天趋势")
                    .font(adaptiveTitleFont)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                // 数据类型选择器
                Picker("", selection: $selectedTab) {
                    Text("步数").tag(0)
                    Text("消耗").tag(1)
                    Text("运动").tag(2)
                }
                .pickerStyle(.segmented)
                .scaleEffect(geometry.size.width < 400 ? 0.9 : 1.0)
                
                // 图表
                Chart(weeklyData) { data in
                    switch selectedTab {
                    case 0: // 步数
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("步数", data.steps)
                        )
                        .foregroundStyle(AITheme.primaryGradient)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("步数", data.steps)
                        )
                        .foregroundStyle(AITheme.primaryGradient.opacity(0.3))
                        
                    case 1: // 活动消耗
                        BarMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("卡路里", data.activeEnergyBurned)
                        )
                        .foregroundStyle(AITheme.secondaryGradient)
                        .cornerRadius(4)
                        
                    case 2: // 运动时长
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("分钟", data.workoutTime / 60)
                        )
                        .foregroundStyle(.green)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        
                    default:
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("步数", data.steps)
                        )
                        .foregroundStyle(AITheme.primaryGradient)
                    }
                }
                .frame(height: adaptiveChartHeight)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(chineseWeekdayFormatter.string(from: date))
                                    .font(AITypography.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
    }
}

/**
 * 完整的周数据列表视图（非紧凑布局）
 */
struct FullWeeklyDataView: View {
    let weeklyData: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AISpacing.md) {
            Text("数据详情")
                .font(AITypography.title2)
                .fontWeight(.bold)
                .foregroundColor(AITheme.textPrimary)
            
            if weeklyData.isEmpty {
                AICard {
                    Text("暂无历史数据")
                        .font(AITypography.headline)
                        .foregroundColor(AITheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(AISpacing.lg)
                }
            } else {
                LazyVStack(spacing: AISpacing.sm) {
                    ForEach(weeklyData.sorted { $0.date > $1.date }) { data in
                        FullDataRow(data: data)
                    }
                }
            }
        }
    }
}

/**
 * 完整数据行
 */
struct FullDataRow: View {
    let data: HealthData
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(data.date)
    }
    
    var body: some View {
        AICard(padding: AISpacing.md, isElevated: false) {
            HStack {
                VStack(alignment: .leading, spacing: AISpacing.xs) {
                    HStack {
                        Text(dateFormatter.string(from: data.date))
                            .font(AITypography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(AITheme.textPrimary)
                        
                        if isToday {
                            Text("今天")
                                .font(AITypography.caption)
                                .padding(.horizontal, AISpacing.sm)
                                .padding(.vertical, 2)
                                .background(AITheme.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AIRadius.sm)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: AISpacing.md) {
                        Label("\(data.steps)", systemImage: "figure.walk")
                            .font(AITypography.caption)
                            .foregroundColor(AITheme.textSecondary)
                        
                        Label(String(format: "%.0f", data.activeEnergyBurned), systemImage: "flame.fill")
                            .font(AITypography.caption)
                            .foregroundColor(AITheme.textSecondary)
                        
                        Label(String(format: "%.0f min", data.workoutTime / 60), systemImage: "timer")
                            .font(AITypography.caption)
                            .foregroundColor(AITheme.textSecondary)
                    }
                }
                
                Spacer()
                
                // 达标指示器
                if data.steps >= 10000 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AITheme.success)
                }
            }
        }
        .background(isToday ? AITheme.accent.opacity(0.05) : Color.clear)
        .cornerRadius(AIRadius.md)
    }
}

/**
 * 紧凑布局的周数据视图
 */
struct CompactWeeklyDataView: View {
    let weeklyData: [HealthData]
    let geometry: GeometryProxy
    
    /// 只显示最近3天的数据
    private var recentData: [HealthData] {
        Array(weeklyData.sorted { $0.date > $1.date }.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AISpacing.sm) {
            HStack {
                Text("最近数据")
                    .font(AITypography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                Spacer()
                
                Button("查看全部") {
                    // 可以添加导航到详细页面的逻辑
                }
                .font(AITypography.caption)
                .foregroundColor(AITheme.accent)
            }
            
            LazyVStack(spacing: AISpacing.xs) {
                ForEach(recentData) { data in
                    CompactDataRow(data: data)
                }
            }
        }
    }
}

/**
 * 紧凑数据行
 */
struct CompactDataRow: View {
    let data: HealthData
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(data.date)
    }
    
    var body: some View {
        HStack(spacing: AISpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: data.date))
                    .font(AITypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? AITheme.accent : AITheme.textPrimary)
                
                if isToday {
                    Text("今天")
                        .font(AITypography.caption)
                        .foregroundColor(AITheme.accent)
                }
            }
            .frame(width: 40, alignment: .leading)
            
            HStack(spacing: AISpacing.sm) {
                Label("\(data.steps)", systemImage: "figure.walk")
                    .font(AITypography.caption)
                    .foregroundColor(AITheme.textSecondary)
                    .lineLimit(1)
                
                Label("\(Int(data.activeEnergyBurned))", systemImage: "flame.fill")
                    .font(AITypography.caption)
                    .foregroundColor(AITheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if data.steps >= 10000 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(AITheme.success)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, AISpacing.sm)
        .background(isToday ? AITheme.accent.opacity(0.08) : AITheme.surface)
        .cornerRadius(AIRadius.sm)
    }
}

// MARK: - 无数据视图

/**
 * 无数据提示视图
 */
struct NoDataView: View {
    var body: some View {
        AICard {
            VStack(spacing: AISpacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(AITheme.primaryGradient)
                
                Text("暂无健康数据")
                    .font(AITypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AITheme.textPrimary)
                
                Text("开始使用设备记录您的健康数据，\n或手动添加健康记录")
                    .font(AITypography.body)
                    .foregroundColor(AITheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(AISpacing.xl)
        }
    }
}

// MARK: - 权限视图组件

/**
 * 简化的权限请求视图
 */
struct SimplePermissionRequestView: View {
    let missingPermissions: [HKObjectType]
    let onPermissionRequested: () async -> Void
    @EnvironmentObject var healthKitService: HealthKitService
    
    var body: some View {
        AICard {
            VStack(spacing: AISpacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AITheme.primaryGradient)
                
                Text("需要健康数据权限")
                    .font(AITypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                Text("应用需要访问以下健康数据以提供个性化建议：")
                    .font(AITypography.body)
                    .foregroundColor(AITheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: AISpacing.sm) {
                    ForEach(Array(missingPermissions.enumerated()), id: \.offset) { _, permission in
                        HStack {
                            Image(systemName: permissionIcon(for: permission))
                                .foregroundColor(AITheme.accent)
                            Text(permissionName(for: permission))
                                .font(AITypography.callout)
                                .foregroundColor(AITheme.textPrimary)
                        }
                    }
                }
                
                AIPrimaryButton("授权访问", icon: "heart.fill", isLoading: false) {
                    Task {
                        await healthKitService.requestAuthorization()
                        await onPermissionRequested()
                    }
                }
            }
            .padding(AISpacing.lg)
        }
    }
    
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
}

/**
 * 初始权限视图
 */
struct InitialPermissionView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    
    var body: some View {
        AICard {
            VStack(spacing: AISpacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AITheme.primaryGradient)
                
                Text("欢迎使用 FitWise AI")
                    .font(AITypography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
                
                Text("为了提供个性化的健康建议，我们需要访问您的健康数据")
                    .font(AITypography.body)
                    .foregroundColor(AITheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: AISpacing.sm) {
                    PermissionRowView(icon: "figure.walk", title: "步数", description: "追踪您的日常活动")
                    PermissionRowView(icon: "heart.fill", title: "心率", description: "监测运动强度")
                    PermissionRowView(icon: "flame.fill", title: "卡路里", description: "计算能量消耗")
                    PermissionRowView(icon: "location.fill", title: "距离", description: "记录运动距离")
                }
                
                AIPrimaryButton("开始授权", icon: "arrow.right", isLoading: false) {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
            }
            .padding(AISpacing.xl)
        }
    }
}

/**
 * 权限行视图
 */
struct PermissionRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AISpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AITheme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AITypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AITheme.textPrimary)
                
                Text(description)
                    .font(AITypography.caption)
                    .foregroundColor(AITheme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
}

#Preview {
    HomeView()
        .environmentObject(HealthKitService())
}