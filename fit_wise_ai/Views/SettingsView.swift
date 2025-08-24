//
//  SettingsView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

/**
 * 应用设置视图
 * 
 * 提供用户配置应用行为的界面，包括：
 * 1. HealthKit权限管理
 * 2. 数据刷新频率设置
 * 3. AI建议偏好设置
 * 4. OpenAI API密钥配置
 * 5. 数据管理功能
 */
struct SettingsView: View {
    @StateObject private var viewModel = HealthDataViewModel()
    @EnvironmentObject var healthKitService: HealthKitService
    
    // 持久化存储
    @AppStorage("openai_api_key") private var apiKey = ""
    @AppStorage("ai_base_url") private var baseURL = ""
    @AppStorage("auto_refresh_enabled") private var autoRefreshEnabled = true
    @AppStorage("refresh_interval") private var refreshInterval = 6.0 // 小时
    @AppStorage("advice_categories") private var adviceCategories = "exercise,nutrition,rest"
    @AppStorage("notification_enabled") private var notificationEnabled = false
    
    // 状态管理
    @State private var showingAPIKeySheet = false
    @State private var showingClearDataAlert = false
    @State private var showingAboutSheet = false
    @State private var showingAdviceHistory = false
    @State private var showingProviderSheet = false
    @State private var showingCustomURLSheet = false
    @State private var selectedProvider = AIProvider.openAI
    @State private var customBaseURL = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 透明背景以显示渐变
                Color.clear
                
                ScrollView {
                    VStack(spacing: AISpacing.lg) {
                        // 现代化HealthKit权限管理
                        ModernSettingsSection(title: "健康数据", icon: "heart.fill", color: .red) {
                            ModernSettingsRow(
                                icon: "heart.text.square",
                                iconColor: .red,
                                title: "HealthKit权限",
                                value: healthKitService.isAuthorized ? "已授权" : "未授权",
                                valueColor: healthKitService.isAuthorized ? AITheme.success : AITheme.warning,
                                showArrow: !healthKitService.isAuthorized
                            ) {
                                if !healthKitService.isAuthorized {
                                    Task {
                                        await healthKitService.requestAuthorization()
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, AISpacing.xs)
                            
                            ModernSettingsToggle(
                                icon: "arrow.clockwise",
                                iconColor: .blue,
                                title: "自动刷新数据",
                                subtitle: "定期从HealthKit获取最新数据",
                                isOn: $autoRefreshEnabled
                            )
                            
                            if autoRefreshEnabled {
                                Divider()
                                    .padding(.vertical, AISpacing.xs)
                                
                                HStack(spacing: AISpacing.md) {
                                    Image(systemName: "clock")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    
                                    Text("刷新间隔")
                                        .font(AITypography.body)
                                        .foregroundColor(AITheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $refreshInterval) {
                                        Text("3小时").tag(3.0)
                                        Text("6小时").tag(6.0)
                                        Text("12小时").tag(12.0)
                                        Text("24小时").tag(24.0)
                                    }
                                    .pickerStyle(.menu)
                                    .tint(AITheme.accent)
                                }
                                .padding(.vertical, AISpacing.xs)
                            }
                        }
                        
                        // 现代化AI服务配置
                        ModernSettingsSection(
                            title: "AI服务", 
                            icon: "sparkles", 
                            color: AITheme.accent,
                            footer: "FitWise AI支持多种AI服务提供商，包括OpenAI、Claude、DeepSeek等"
                        ) {
                            // AI服务提供商选择
                            ModernSettingsRow(
                                icon: "globe",
                                iconColor: .purple,
                                title: "AI服务提供商",
                                value: currentProviderName
                            ) {
                                showingProviderSheet = true
                            }
                            
                            Divider()
                                .padding(.vertical, AISpacing.xs)
                            
                            // API密钥配置
                            ModernSettingsRow(
                                icon: "key.fill",
                                iconColor: .orange,
                                title: "API密钥",
                                value: apiKey.isEmpty ? "未配置" : "已配置",
                                valueColor: apiKey.isEmpty ? AITheme.error : AITheme.success
                            ) {
                                showingAPIKeySheet = true
                            }
                            
                            // 显示当前baseURL（如果是自定义的话）
                            if !baseURL.isEmpty && currentProviderName == "自定义" {
                                Divider()
                                    .padding(.vertical, AISpacing.xs)
                                
                                HStack(spacing: AISpacing.md) {
                                    Image(systemName: "link")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("服务地址")
                                            .font(AITypography.body)
                                            .foregroundColor(AITheme.textPrimary)
                                        Text(baseURL)
                                            .font(AITypography.caption)
                                            .foregroundColor(AITheme.textSecondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("修改") {
                                        customBaseURL = baseURL
                                        showingCustomURLSheet = true
                                    }
                                    .font(AITypography.caption)
                                    .foregroundColor(AITheme.accent)
                                    .padding(.horizontal, AISpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AITheme.accent.opacity(0.1))
                                    .cornerRadius(AIRadius.sm)
                                }
                                .padding(.vertical, AISpacing.xs)
                            }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("建议类型偏好")
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(["运动", "营养", "休息"], id: \.self) { category in
                                let isSelected = adviceCategories.contains(categoryKey(for: category))
                                Text(category)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(15)
                                    .onTapGesture {
                                        toggleCategory(category)
                                    }
                            }
                        }
                        .padding(.leading, 32)
                    }
                    
                    // 网络状态
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(viewModel.networkService.isConnected ? .green : .red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("网络状态")
                                .foregroundColor(.primary)
                            Text(viewModel.networkService.isConnected ? 
                                 "已连接 (\(viewModel.networkService.connectionType.description))" : 
                                 "未连接")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.networkService.isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                        }
                        
                        // 现代化通知设置
                        ModernSettingsSection(title: "通知", icon: "bell.fill", color: .blue) {
                    Toggle(isOn: $notificationEnabled) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("健康建议推送")
                        }
                    }
                    
                    if notificationEnabled {
                        HStack {
                            Image(systemName: "alarm")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("推送时间")
                            Spacer()
                            Text("每日 9:00")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                        }
                        
                        // 现代化数据管理
                        ModernSettingsSection(title: "数据管理", icon: "externaldrive.fill", color: .orange) {
                    Button(action: { showingAdviceHistory = true }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("建议历史")
                            Spacer()
                            Text("\(viewModel.persistenceService.adviceHistory.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: openHealthApp) {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("打开健康应用")
                        }
                    }
                    
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("清除本地缓存")
                                .foregroundColor(.red)
                        }
                    }
                        }
                        
                        // 现代化关于
                        ModernSettingsSection(title: "关于", icon: "info.circle.fill", color: .green) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        showingAboutSheet = true
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourapp/privacy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourapp/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("使用条款")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                    }
                    .padding(AISpacing.md)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeyConfigView(apiKey: $apiKey)
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
            .sheet(isPresented: $showingAdviceHistory) {
                AdviceHistoryView()
            }
            .sheet(isPresented: $showingProviderSheet) {
                AIProviderSelectionView(
                    selectedProvider: $selectedProvider,
                    baseURL: $baseURL,
                    customBaseURL: $customBaseURL,
                    showingCustomURLSheet: $showingCustomURLSheet
                )
            }
            .sheet(isPresented: $showingCustomURLSheet) {
                CustomURLConfigView(
                    customBaseURL: $customBaseURL,
                    baseURL: $baseURL
                )
            }
            .onAppear {
                // 根据保存的baseURL确定当前选中的提供商
                selectedProvider = AIProvider.from(baseURL: baseURL)
            }
            .alert("清除缓存", isPresented: $showingClearDataAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearLocalCache()
                }
            } message: {
                Text("确定要清除所有本地缓存数据吗？这不会影响您的健康数据。")
            }
        }
    }
    
    private func categoryKey(for category: String) -> String {
        switch category {
        case "运动": return "exercise"
        case "营养": return "nutrition"
        case "休息": return "rest"
        default: return ""
        }
    }
    
    private func toggleCategory(_ category: String) {
        let key = categoryKey(for: category)
        var categories = adviceCategories.split(separator: ",").map(String.init)
        
        if let index = categories.firstIndex(of: key) {
            categories.remove(at: index)
        } else {
            categories.append(key)
        }
        
        adviceCategories = categories.joined(separator: ",")
    }
    
    private var currentProviderName: String {
        if baseURL.isEmpty {
            return AIProvider.openAI.name
        }
        return AIProvider.from(baseURL: baseURL).name
    }
    
    private func clearLocalCache() {
        UserDefaults.standard.removeObject(forKey: "cached_health_data")
        UserDefaults.standard.removeObject(forKey: "cached_ai_advice")
    }
    
    private func openHealthApp() {
        if let healthURL = URL(string: "x-apple-health://") {
            UIApplication.shared.open(healthURL)
        }
    }
}

// MARK: - API密钥配置视图
struct APIKeyConfigView: View {
    @Binding var apiKey: String
    @State private var tempKey = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("输入OpenAI API密钥", text: $tempKey)
                        .textContentType(.password)
                } header: {
                    Text("API密钥")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("您的API密钥将安全地存储在本地")
                        Link("获取API密钥", destination: URL(string: "https://platform.openai.com/api-keys")!)
                            .font(.caption)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("安全提示", systemImage: "lock.shield")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("• API密钥仅存储在您的设备上")
                        Text("• 不会上传到任何服务器")
                        Text("• 请勿与他人分享您的API密钥")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("配置API密钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        apiKey = tempKey
                        dismiss()
                    }
                    .disabled(tempKey.isEmpty)
                }
            }
        }
        .onAppear {
            tempKey = apiKey
        }
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App图标和名称
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("FitWise AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("智能健康管理助手")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 版本信息
                    VStack(spacing: 12) {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0 (Build 1)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("最低系统要求")
                            Spacer()
                            Text("iOS 16.0+")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 功能介绍
                    VStack(alignment: .leading, spacing: 16) {
                        Text("主要功能")
                            .font(.headline)
                        
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "7天健康趋势", description: "追踪并可视化您的健康数据")
                        FeatureRow(icon: "sparkles", title: "AI个性化建议", description: "基于您的数据生成智能建议")
                        FeatureRow(icon: "heart.text.square", title: "HealthKit集成", description: "无缝同步您的健康数据")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 开发者信息
                    VStack(spacing: 8) {
                        Text("开发者")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("© 2025 FitWise AI Team")
                            .font(.footnote)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - AI服务提供商选择视图
struct AIProviderSelectionView: View {
    @Binding var selectedProvider: AIProvider
    @Binding var baseURL: String
    @Binding var customBaseURL: String
    @Binding var showingCustomURLSheet: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("选择AI服务提供商")) {
                    ForEach(AIProvider.allProviders, id: \.name) { provider in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if !provider.isCustom {
                                    Text(provider.baseURL)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedProvider.name == provider.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProvider = provider
                            
                            if provider.isCustom {
                                // 如果选择自定义，显示URL输入界面
                                showingCustomURLSheet = true
                            } else {
                                // 保存预设的baseURL
                                baseURL = provider.baseURL
                                dismiss()
                            }
                        }
                    }
                }
                
                Section(footer: Text("选择您偏好的AI服务提供商。不同提供商可能有不同的定价和性能特点。")) {
                    EmptyView()
                }
            }
            .navigationTitle("AI服务提供商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 自定义URL配置视图
struct CustomURLConfigView: View {
    @Binding var customBaseURL: String
    @Binding var baseURL: String
    @State private var tempURL = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("https://api.example.com/v1", text: $tempURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("自定义API地址")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("请输入完整的API基础地址，例如：")
                        Text("https://api.example.com/v1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("系统会自动添加/chat/completions端点")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("使用说明", systemImage: "info.circle")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("• 确保API兼容OpenAI格式")
                        Text("• 输入基础URL，不包含具体端点")
                        Text("• 支持https://和http://协议")
                        Text("• 确保网络可以访问该地址")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("自定义API地址")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        baseURL = tempURL
                        customBaseURL = tempURL
                        dismiss()
                    }
                    .disabled(tempURL.isEmpty || !isValidURL(tempURL))
                }
            }
        }
        .onAppear {
            tempURL = customBaseURL
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }
}

// MARK: - 现代化设置UI组件

struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let footer: String?
    let content: Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.footer = footer
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AISpacing.md) {
            // 区域标题
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(AITypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AITheme.textPrimary)
            }
            .padding(.horizontal, AISpacing.sm)
            
            // 设置项内容
            AICard {
                VStack(spacing: AISpacing.md) {
                    content
                }
            }
            
            // 底部说明文字
            if let footer = footer {
                Text(footer)
                    .font(AITypography.caption)
                    .foregroundColor(AITheme.textSecondary)
                    .padding(.horizontal, AISpacing.sm)
            }
        }
    }
}

struct ModernSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let valueColor: Color?
    let showArrow: Bool
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        valueColor: Color? = nil,
        showArrow: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueColor = valueColor
        self.showArrow = showArrow
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: AISpacing.md) {
                // 图标
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24, alignment: .center)
                
                // 标题和副标题
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AITypography.body)
                        .foregroundColor(AITheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AITypography.caption)
                            .foregroundColor(AITheme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // 值和箭头
                HStack(spacing: AISpacing.sm) {
                    if let value = value {
                        Text(value)
                            .font(AITypography.caption)
                            .foregroundColor(valueColor ?? AITheme.textSecondary)
                    }
                    
                    if showArrow {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AITheme.textSecondary)
                    }
                }
            }
            .padding(.vertical, AISpacing.xs)
        }
        .disabled(action == nil)
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernSettingsToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AISpacing.md) {
            // 图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, alignment: .center)
            
            // 标题和副标题
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AITypography.body)
                    .foregroundColor(AITheme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AITypography.caption)
                        .foregroundColor(AITheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // 开关
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AITheme.accent)
        }
        .padding(.vertical, AISpacing.xs)
    }
}

#Preview {
    SettingsView()
        .environmentObject(HealthKitService())
}