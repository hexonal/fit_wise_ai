//
//  HomeView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI
import Charts

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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 根据授权状态显示不同内容
                    if !healthKitService.isAuthorized {
                        // 显示权限请求视图
                        PermissionRequestView(viewModel: viewModel, healthKitService: healthKitService)
                            .onAppear {
                                print("🟣 HomeView: PermissionRequestView 显示，当前授权状态: \(healthKitService.isAuthorized)")
                            }
                    } else {
                        // 显示7天健康数据和趋势
                        VStack(spacing: 20) {
                            // 今日健康统计数据展示
                            HealthStatsView(healthData: viewModel.healthData)
                            
                            // 7天数据趋势图表
                            if !healthKitService.weeklyHealthData.isEmpty {
                                WeeklyChartsView(weeklyData: healthKitService.weeklyHealthData, selectedTab: $selectedTab)
                            }
                            
                            // 数据详情列表
                            WeeklyDataListView(weeklyData: healthKitService.weeklyHealthData)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("健康概览")
            // 下拉刷新功能
            .refreshable {
                if healthKitService.isAuthorized {
                    await viewModel.refreshHealthData()
                    await healthKitService.fetchWeeklyHealthData()
                }
            }
            // 视图加载时自动刷新数据
            .task {
                if healthKitService.isAuthorized {
                    await viewModel.refreshHealthData()
                    await healthKitService.fetchWeeklyHealthData()
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
                            
                            // 使用新的刷新方法
                            await healthKitService.refreshAuthorizationStatus()
                            
                            // 如果已授权，刷新数据
                            if healthKitService.isAuthorized {
                                print("🟢 PermissionRequestView: 检测到已授权，开始刷新数据")
                                await viewModel.refreshHealthData()
                            } else {
                                print("🟡 PermissionRequestView: 仍未授权，请在设置中手动开启权限")
                                showPermissionDeniedAlert = true
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
                    
                    // 前往设置
                    Button(action: {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("前往iPhone设置")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 帮助文本
                    Text("如果权限被拒绝，请尝试：\n1. 点击\"前往iPhone设置\"手动开启权限\n2. 或在健康App中找到本应用并授权\n3. 确保健康App中有数据记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    // 添加前往健康App的按钮
                    Button(action: {
                        if let healthUrl = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(healthUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.red)
                            Text("打开健康App")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .alert("权限被拒绝", isPresented: $showPermissionDeniedAlert) {
            Button("前往设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("稍后再说", role: .cancel) { }
        } message: {
            Text("健康数据权限已被拒绝。请在iPhone设置 > 隐私与安全性 > 健康 > 健身智慧AI中开启相关权限。")
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
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
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