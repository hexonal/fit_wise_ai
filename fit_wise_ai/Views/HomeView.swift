//
//  HomeView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI
import Charts
import HealthKit

/**
 * 应用首页视图
 * 
 * 首页是用户的主要交互界面，负责：
 * 1. 健康数据授权管理
 * 2. 7天健康数据趋势展示
 * 3. 数据可视化图表
 * 4. 关键指标汇总
 * 5. 下拉刷新功能
 * 
 * 视图会根据 HealthKit 授权状态显示不同内容：
 * - 未授权：显示权限请求界面
 * - 已授权：显示7天健康数据和趋势图表
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
            if isCheckingPermissions {
                // 权限检查加载界面
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在检查健康数据权限...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 根据权限状态显示不同内容
                        if !missingPermissions.isEmpty {
                            // 显示权限请求视图
                            EnhancedPermissionRequestView(
                                viewModel: viewModel, 
                                healthKitService: healthKitService,
                                missingPermissions: missingPermissions,
                                onPermissionUpdate: {
                                    await checkPermissionsAndRefreshData()
                                }
                            )
                        } else if healthKitService.isAuthorized {
                            // 显示7天健康数据和趋势
                            VStack(spacing: 20) {
                                // 今日健康统计数据展示
                                HealthStatsView(healthData: viewModel.healthData)
                                
                                // 7天数据趋势图表
                                if !healthKitService.weeklyHealthData.isEmpty {
                                    WeeklyChartsView(weeklyData: healthKitService.weeklyHealthData, selectedTab: $selectedTab)
                                } else {
                                    // 没有数据时的提示
                                    VStack(spacing: 12) {
                                        Text("暂无历史数据")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        
                                        #if targetEnvironment(simulator)
                                        Text("💡 在模拟器中测试时，请到健康App中添加一些示例数据")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        #else
                                        Text("开始使用Apple Watch或iPhone记录健康数据后，这里将显示您的健康趋势")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        #endif
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                // 数据详情列表
                                WeeklyDataListView(weeklyData: healthKitService.weeklyHealthData)
                            }
                        } else {
                            // 权限未授权的备用视图
                            PermissionRequestView(viewModel: viewModel, healthKitService: healthKitService)
                        }
                    }
                    .padding()
                }
                .navigationTitle("健康概览")
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
    
    /// 检查HealthKit权限状态并刷新健康数据
    /// 
    /// 此方法执行完整的权限检查流程：
    /// 1. 检查应用所需的4个核心HealthKit权限（步数、距离、活动能量、心率）
    /// 2. 如果所有权限都已授权，则刷新今日和历史健康数据
    /// 3. 更新UI状态以反映权限检查结果
    private func checkPermissionsAndRefreshData() async {
        print("🔵 HomeView: 开始权限检查流程")
        isCheckingPermissions = true
        
        // 首先检查当前授权状态
        await healthKitService.checkCurrentAuthorizationStatus()
        print("🔵 HomeView: 权限检查完成，isAuthorized: \(healthKitService.isAuthorized)")
        
        // 检查应用必需的HealthKit权限，返回缺失的权限类型
        let missing = healthKitService.checkRequiredPermissions()
        missingPermissions = missing
        print("🔵 HomeView: 缺失权限数量: \(missing.count), isAuthorized: \(healthKitService.isAuthorized)")
        
        if missing.isEmpty && healthKitService.isAuthorized {
            // 所有权限都已授权，开始获取健康数据
            print("🔵 HomeView: 权限完整，开始获取数据")
            await viewModel.refreshHealthData()
            await healthKitService.fetchWeeklyHealthData()
        } else {
            print("🔵 HomeView: 权限不完整，将显示权限请求界面")
        }
        
        // 权限检查完成，更新UI状态
        isCheckingPermissions = false
    }
}

/**
 * 增强版权限请求视图
 * 
 * 相比基础的权限请求视图，此版本提供了以下增强功能：
 * 1. 显示具体缺失的权限类型列表（步数、心率等）
 * 2. 提供权限说明和用户指导
 * 3. 授权完成后自动触发权限状态刷新
 * 4. 友好的中文权限名称显示
 */
struct EnhancedPermissionRequestView: View {
    let viewModel: HealthDataViewModel
    let healthKitService: HealthKitService
    /// 缺失的HealthKit权限类型数组
    let missingPermissions: [HKObjectType]
    /// 权限更新后的回调函数，用于刷新父视图状态
    let onPermissionUpdate: () async -> Void
    /// 是否正在请求权限的状态标识
    @State private var isRequesting = false
    
    /// 将HealthKit权限标识符转换为用户友好的中文名称
    /// - Parameter type: HealthKit权限类型
    /// - Returns: 对应的中文权限名称
    private func getPermissionName(for type: HKObjectType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "步数"
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return "步行+跑步距离"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "活动能量"
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return "心率"
        default:
            return type.identifier
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 权限图标
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // 标题
            Text("需要健康数据访问权限")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 说明
            Text("为了为您提供个性化的健身建议，需要获取以下健康数据的访问权限：")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // 缺失权限列表
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(missingPermissions.enumerated()), id: \.offset) { index, permission in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(getPermissionName(for: permission))
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // 授权按钮
            Button(action: {
                guard !isRequesting else { return }
                isRequesting = true
                
                Task {
                    await healthKitService.requestAuthorization()
                    
                    // 授权完成后，等待一下再检查状态
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                    
                    // 刷新权限状态并通知父视图
                    await onPermissionUpdate()
                    
                    isRequesting = false
                }
            }) {
                if isRequesting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("正在请求授权...")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
                } else {
                    Text("授权访问健康数据")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(isRequesting)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
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
    let healthKitService: HealthKitService
    @State private var isRequesting = false
    @State private var showPermissionDeniedAlert = false
    @State private var hasAttemptedAuth = false
    
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
                print("🔵 PermissionRequestView: 授权按钮被点击, isRequesting: \(isRequesting)")
                guard !isRequesting else {
                    print("🟠 PermissionRequestView: 正在请求中，忽略重复点击")
                    return
                }
                
                isRequesting = true
                print("🔵 PermissionRequestView: 设置 isRequesting = true")
                
                Task {
                    print("🔵 PermissionRequestView: 开始请求HealthKit授权")
                    await healthKitService.requestAuthorization()
                    print("🔵 PermissionRequestView: 授权请求完成，授权状态: \(healthKitService.isAuthorized)")
                    
                    hasAttemptedAuth = true
                    
                    if healthKitService.isAuthorized {
                        print("🔵 PermissionRequestView: 已授权，开始刷新健康数据")
                        await viewModel.refreshHealthData()
                        print("🔵 PermissionRequestView: 健康数据刷新完成")
                    } else {
                        print("🔴 PermissionRequestView: 未授权，显示权限被拒绝提示")
                        showPermissionDeniedAlert = true
                    }
                    
                    isRequesting = false
                    print("🔵 PermissionRequestView: 设置 isRequesting = false")
                }
            }) {
                if isRequesting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("正在请求授权...")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
                } else {
                    Text("授权访问健康数据")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .disabled(isRequesting)
            
            // 如果已经尝试过授权但失败，显示多种解决方案
            if hasAttemptedAuth && !healthKitService.isAuthorized {
                VStack(spacing: 12) {
                    // 刷新授权状态
                    Button(action: {
                        guard !isRequesting else { return }
                        isRequesting = true
                        
                        Task {
                            print("🔵 PermissionRequestView: 刷新授权状态")
                            await healthKitService.refreshAuthorizationStatus()
                            
                            if healthKitService.isAuthorized {
                                print("🟢 PermissionRequestView: 检测到已授权，开始刷新数据")
                                await viewModel.refreshHealthData()
                            }
                            
                            isRequesting = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("刷新授权状态")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(isRequesting)
                    
                    
                    // 帮助文本
                    Text("HealthKit读权限说明：\n1. 系统会弹出权限对话框，请选择\"允许\"\n2. 读权限不会显示在iPhone设置中\n3. 如仍有问题，请点击\"刷新授权状态\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .alert("权限被拒绝", isPresented: $showPermissionDeniedAlert) {
            Button("重新授权") {
                Task {
                    await healthKitService.requestAuthorization()
                }
            }
            Button("稍后再说", role: .cancel) { }
        } message: {
            Text("HealthKit健康数据访问权限被拒绝。请在系统权限对话框中选择\"允许\"以获取健康数据。注意：HealthKit读权限不会显示在iPhone设置中。")
        }
    }
}

/**
 * 7天数据趋势图表视图
 * 
 * 使用 Swift Charts 展示7天健康数据趋势
 * 支持步数、心率、活动能量等多种数据类型切换
 */
struct WeeklyChartsView: View {
    let weeklyData: [HealthData]
    @Binding var selectedTab: Int
    
    /// 中文星期格式器
    private var chineseWeekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7天趋势")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 数据类型选择器
            Picker("", selection: $selectedTab) {
                Text("步数").tag(0)
                Text("消耗").tag(1)
                Text("运动").tag(2)
            }
            .pickerStyle(.segmented)
            
            // 图表
            Chart(weeklyData) { data in
                switch selectedTab {
                case 0: // 步数
                    LineMark(
                        x: .value("日期", data.date, unit: .day),
                        y: .value("步数", data.steps)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle())
                    
                    AreaMark(
                        x: .value("日期", data.date, unit: .day),
                        y: .value("步数", data.steps)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    
                case 1: // 活动消耗
                    BarMark(
                        x: .value("日期", data.date, unit: .day),
                        y: .value("卡路里", data.activeEnergyBurned)
                    )
                    .foregroundStyle(.orange)
                    
                case 2: // 运动时长
                    LineMark(
                        x: .value("日期", data.date, unit: .day),
                        y: .value("分钟", data.workoutTime / 60)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                    
                default:
                    // 默认显示步数图表
                    LineMark(
                        x: .value("日期", data.date, unit: .day),
                        y: .value("步数", data.steps)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle())
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(chineseWeekdayFormatter.string(from: date))
                                .font(.caption)
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
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/**
 * 7天数据详情列表视图
 * 
 * 展示7天健康数据的详细列表
 * 包含每日的步数、消耗、运动时长等指标
 */
struct WeeklyDataListView: View {
    let weeklyData: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("数据详情")
                .font(.title2)
                .fontWeight(.semibold)
            
            if weeklyData.isEmpty {
                Text("暂无历史数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(weeklyData.sorted { $0.date > $1.date }) { data in
                    WeeklyDataRow(data: data)
                }
            }
        }
    }
}

/**
 * 单日数据行视图
 */
struct WeeklyDataRow: View {
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dateFormatter.string(from: data.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if isToday {
                        Text("今天")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(data.steps)", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(String(format: "%.0f kcal", data.activeEnergyBurned), systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(String(format: "%.0f min", data.workoutTime / 60), systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 达标指示器
            if data.steps >= 10000 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isToday ? Color.blue.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}


#Preview {
    HomeView()
        .environmentObject(HealthKitService())
}