//
//  AdviceHistoryView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/14.
//

import SwiftUI
import Foundation

/**
 * AI建议历史记录视图
 * 
 * 展示用户的AI建议历史，支持：
 * 1. 按分类筛选建议
 * 2. 按时间排序显示
 * 3. 建议详情查看
 * 4. 历史统计分析
 */
struct AdviceHistoryView: View {
    /// 数据持久化服务
    @StateObject private var persistenceService = DataPersistenceService()
    /// 选择的建议分类筛选器
    @State private var selectedCategory: AdviceCategory? = nil
    /// 搜索关键词
    @State private var searchText = ""
    /// 是否显示统计视图
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()
                adviceListContent
            }
            .navigationTitle("建议历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .sheet(isPresented: $showingStatistics) {
                AdviceStatisticsView(advice: persistenceService.adviceHistory)
            }
        }
    }
    
    /// 筛选器栏视图
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部按钮
                FilterButton(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // 分类筛选按钮
                ForEach(AdviceCategory.allCases, id: \.self) { category in
                    FilterButton(
                        title: category.rawValue,
                        icon: category.icon,
                        color: Color(category.color),
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    /// 建议列表内容视图
    private var adviceListContent: some View {
        Group {
            if filteredAdvice.isEmpty {
                emptyStateView
            } else {
                adviceListView
            }
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无历史建议")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("开始使用应用后，您的AI建议历史将显示在这里")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    /// 建议列表视图
    private var adviceListView: some View {
        List {
            ForEach(groupedAdvice.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(groupedAdvice[date] ?? []) { advice in
                        AdviceHistoryRow(advice: advice)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .searchable(text: $searchText, prompt: "搜索建议内容...")
    }
    
    /// 工具栏菜单
    private var toolbarMenu: some View {
        Menu {
            Button(action: { showingStatistics = true }) {
                Label("查看统计", systemImage: "chart.bar")
            }
            
            Button(action: exportHistory) {
                Label("导出历史", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive, action: clearHistory) {
                Label("清空历史", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    /**
     * 筛选后的建议列表
     */
    private var filteredAdvice: [AIAdviceRecord] {
        var advice = persistenceService.adviceHistory
        
        // 按分类筛选
        if let category = selectedCategory {
            advice = advice.filter { $0.category == category.rawValue }
        }
        
        // 按搜索关键词筛选
        if !searchText.isEmpty {
            advice = advice.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return advice.sorted { $0.createdAt > $1.createdAt }
    }
    
    /**
     * 按日期分组的建议
     */
    private var groupedAdvice: [Date: [AIAdviceRecord]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredAdvice) { advice in
            calendar.startOfDay(for: advice.createdAt)
        }
    }
    
    /**
     * 创建分组标题
     */
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(formatDate(date))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\((groupedAdvice[date] ?? []).count)条建议")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    /**
     * 格式化日期显示
     */
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
    
    /**
     * 导出历史记录
     */
    private func exportHistory() {
        guard let data = persistenceService.exportHealthData() else {
            return
        }
        
        // 这里可以添加分享功能
        print("导出建议历史: \(data.count) 字节")
    }
    
    /**
     * 清空历史记录
     */
    private func clearHistory() {
        persistenceService.adviceHistory.removeAll()
        print("建议历史已清空")
    }
}

/**
 * 筛选按钮组件
 */
struct FilterButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, 
         icon: String? = nil, 
         color: Color = .blue, 
         isSelected: Bool, 
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 建议历史行组件
 */
struct AdviceHistoryRow: View {
    let advice: AIAdviceRecord
    
    private var category: AdviceCategory? {
        AdviceCategory.allCases.first { $0.rawValue == advice.category }
    }
    
    private var priority: AdvicePriority? {
        AdvicePriority.allCases.first { $0.rawValue == advice.priority }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题和时间
            HStack {
                HStack(spacing: 8) {
                    if let category = category {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundColor(Color(category.color))
                    }
                    
                    Text(advice.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text(formatTime(advice.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 建议内容
            Text(advice.content)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // 优先级标签
            if let priority = priority, priority != .medium {
                HStack {
                    Spacer()
                    Text(priority.rawValue + "优先级")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(priority).opacity(0.2))
                        .foregroundColor(priorityColor(priority))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    /**
     * 格式化时间显示
     */
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /**
     * 获取优先级颜色
     */
    private func priorityColor(_ priority: AdvicePriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .blue
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

/**
 * 建议统计视图
 */
struct AdviceStatisticsView: View {
    let advice: [AIAdviceRecord]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 总体统计
                    StatCard(
                        title: "总建议数",
                        value: "\(advice.count)",
                        icon: "lightbulb.fill",
                        color: .blue
                    )
                    
                    // 分类统计
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类统计")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(AdviceCategory.allCases, id: \.self) { category in
                            let count = advice.filter { $0.category == category.rawValue }.count
                            if count > 0 {
                                CategoryStatRow(
                                    category: category,
                                    count: count,
                                    percentage: Double(count) / Double(advice.count)
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("建议统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/**
 * 统计卡片组件
 */
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * 分类统计行组件
 */
struct CategoryStatRow: View {
    let category: AdviceCategory
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Color(category.color))
                .frame(width: 20)
            
            Text(category.rawValue)
                .font(.body)
            
            Spacer()
            
            Text("\(count)")
                .font(.body)
                .fontWeight(.semibold)
            
            Text("(\(Int(percentage * 100))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdviceHistoryView()
}