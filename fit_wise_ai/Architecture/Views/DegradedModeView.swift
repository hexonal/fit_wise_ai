//
//  DegradedModeView.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import SwiftUI

/**
 * 降级模式视图
 * 
 * 当系统处于降级状态时显示，提供基本功能和恢复选项
 */
struct DegradedModeView: View {
    @EnvironmentObject var coordinator: ApplicationCoordinator
    
    var body: some View {
        VStack(spacing: 24) {
            // 状态指示
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("降级运行模式")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("系统正在降级模式下运行，部分功能可能受限")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 系统状态
            VStack(alignment: .leading, spacing: 12) {
                Text("系统状态")
                    .font(.headline)
                
                statusRow("整体健康", coordinator.systemHealth.status, getHealthColor())
                statusRow("Actor系统", coordinator.systemHealth.actorSystemHealthy ? "正常" : "异常", coordinator.systemHealth.actorSystemHealthy ? .green : .red)
                statusRow("事件系统", coordinator.systemHealth.eventSystemHealthy ? "正常" : "异常", coordinator.systemHealth.eventSystemHealthy ? .green : .red)
                statusRow("服务状态", coordinator.systemHealth.servicesHealthy ? "正常" : "异常", coordinator.systemHealth.servicesHealthy ? .green : .red)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await coordinator.triggerHealthCheck()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("检查系统状态")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        await coordinator.resetApplication()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重启应用")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // 查看诊断报告
                NavigationLink(destination: DiagnosticsView()) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("查看详细诊断")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
            
            Text("降级模式下应用可能无法提供完整功能")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("系统状态")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func statusRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
    
    private func getHealthColor() -> Color {
        let score = coordinator.systemHealth.overallScore
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    NavigationView {
        DegradedModeView()
            .environmentObject(ApplicationCoordinator())
    }
}