//
//  InitializationView.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import SwiftUI

/**
 * 应用初始化视图
 * 
 * 在应用启动时显示，展示初始化进度和系统状态
 */
struct InitializationView: View {
    let progress: Double
    let systemHealth: SystemHealthStatus
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo区域
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
                
                Text("FitWise AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("智能健身助手")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 进度指示器
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("初始化中... \(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if progress > 0 {
                    Text(getProgressMessage())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 系统状态指示
            if systemHealth.overallScore > 0 {
                VStack(spacing: 8) {
                    Text("系统状态: \(systemHealth.status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        statusIndicator("Actor", systemHealth.actorSystemHealthy)
                        statusIndicator("Events", systemHealth.eventSystemHealthy)
                        statusIndicator("Services", systemHealth.servicesHealthy)
                    }
                }
            }
            
            Text("基于 Actor Model + Event Sourcing 架构")
                .font(.caption2)
                .foregroundColor(Color.secondary)
                .padding(.bottom, 20)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func getProgressMessage() -> String {
        switch progress {
        case 0.0..<0.2:
            return "启动事件系统..."
        case 0.2..<0.4:
            return "初始化状态机..."
        case 0.4..<0.6:
            return "加载核心服务..."
        case 0.6..<0.8:
            return "启动Actor系统..."
        case 0.8..<0.9:
            return "配置监控系统..."
        default:
            return "准备就绪..."
        }
    }
    
    private func statusIndicator(_ label: String, _ isHealthy: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isHealthy ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    InitializationView(
        progress: 0.6,
        systemHealth: SystemHealthStatus(
            actorSystemHealthy: true,
            eventSystemHealthy: true,
            stateMachineHealthy: false,
            servicesHealthy: false,
            overallScore: 0.5
        )
    )
}