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
        NavigationView {
            if !healthKitService.isAuthorized {
                // 未授权时显示提示
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("需要健康数据授权")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("请先在首页授权访问健康数据，才能获取个性化的AI建议")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await healthKitService.requestAuthorization()
                            if healthKitService.isAuthorized {
                                await loadData()
                            }
                        }
                    }) {
                        Text("前往授权")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
                .navigationTitle("AI建议")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 数据概览卡片
                        weeklyDataSummary
                        
                        // AI建议区域
                        if aiService.isLoading {
                            ProgressView("正在生成个性化建议...")
                                .padding(40)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else if aiService.advice.isEmpty {
                            emptyAdviceView
                        } else {
                            adviceSection
                        }
                    }
                    .padding()
                }
                .navigationTitle("AI建议")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
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
                            } else {
                                Image(systemName: "arrow.clockwise")
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
    
    // MARK: - Views
    
    private var weeklyDataSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("近7天数据概览")
                    .font(.headline)
                Spacer()
            }
            
            if !healthKitService.weeklyHealthData.isEmpty {
                HStack(spacing: 15) {
                    dataSummaryItem(
                        title: "平均步数",
                        value: String(format: "%.0f", averageSteps),
                        icon: "figure.walk",
                        color: .blue
                    )
                    
                    dataSummaryItem(
                        title: "总消耗",
                        value: String(format: "%.0f kcal", totalCalories),
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    dataSummaryItem(
                        title: "运动时长",
                        value: String(format: "%.0f min", totalWorkoutMinutes),
                        icon: "timer",
                        color: .green
                    )
                }
            } else {
                Text("正在加载健康数据...")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func dataSummaryItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emptyAdviceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无AI建议")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("点击刷新按钮获取个性化健康建议")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await refreshData()
                }
            } label: {
                Label("生成建议", systemImage: "sparkles")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("个性化建议")
                    .font(.headline)
                Spacer()
                Text("\(aiService.advice.count)条")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            ForEach(aiService.advice) { advice in
                AdviceCard(advice: advice) {
                    selectedAdvice = advice
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

// MARK: - AdviceCard Component

struct AdviceCard: View {
    let advice: AIAdvice
    let onTap: () -> Void
    
    @State private var isCompleted = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 类别图标
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.1))
                .cornerRadius(10)
            
            // 建议内容
            VStack(alignment: .leading, spacing: 4) {
                Text(advice.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                Text(advice.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 完成按钮
            Button {
                withAnimation(.spring()) {
                    isCompleted.toggle()
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
        }
        .padding()
        .background(isCompleted ? Color.gray.opacity(0.05) : Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onTapGesture {
            onTap()
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
            return .blue
        case .nutrition:
            return .green
        case .rest:
            return .purple
        case .general:
            return .orange
        }
    }
}

#Preview {
    AIAdviceView()
}