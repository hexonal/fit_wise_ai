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
 * 1. 通知设置管理
 * 2. OpenAI API 密钥配置
 * 3. 健康应用快捷访问
 * 4. 应用版本信息显示
 */
struct SettingsView: View {
    /// 推送通知开关状态
    @State private var notificationsEnabled = true
    /// API 密钥输入临时存储
    @State private var apiKeyInput = ""
    /// API 密钥配置界面显示状态
    @State private var showingAPIKeySheet = false
    /// 持久化存储的 OpenAI API 密钥
    @AppStorage("openai_api_key") private var storedAPIKey: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("应用设置") {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Toggle("推送通知", isOn: $notificationsEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Button(action: {
                            apiKeyInput = storedAPIKey
                            showingAPIKeySheet = true
                        }) {
                            HStack {
                                Text("AI API密钥")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(storedAPIKey.isEmpty ? "未设置" : "已设置")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section("健康数据") {
                    Button(action: openHealthApp) {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("打开健康应用")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("关于") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeyConfigView(apiKey: $apiKeyInput, onSave: saveAPIKey)
            }
        }
    }
    
    /**
     * 打开系统健康应用
     * 
     * 使用自定义 URL Scheme 启动 iOS 健康应用
     * 方便用户直接访问健康数据管理界面
     */
    private func openHealthApp() {
        if let healthURL = URL(string: "x-apple-health://") {
            UIApplication.shared.open(healthURL)
        }
    }
    
    /**
     * 保存 API 密钥配置
     * 
     * 将用户输入的 API 密钥保存到本地存储
     * 并关闭配置界面
     */
    private func saveAPIKey() {
        storedAPIKey = apiKeyInput
        showingAPIKeySheet = false
    }
}

/**
 * API 密钥配置视图
 * 
 * 专门用于配置 OpenAI API 密钥的模态视图
 * 提供安全的密钥输入界面和使用说明
 */
struct APIKeyConfigView: View {
    /// 绑定的 API 密钥字符串
    @Binding var apiKey: String
    /// 保存回调函数
    let onSave: () -> Void
    /// 环境变量：用于关闭模态视图
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("配置OpenAI API密钥")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("为了获得AI建议功能，需要配置OpenAI的API密钥。您的密钥将安全地存储在本地设备上。")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API密钥")
                        .font(.headline)
                    
                    SecureField("请输入您的OpenAI API密钥", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("您可以在OpenAI官网（platform.openai.com）获取API密钥")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("API配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}