//
//  DiagnosticsView.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import SwiftUI

/**
 * 系统诊断视图
 * 
 * 显示详细的系统诊断信息和性能统计
 */
struct DiagnosticsView: View {
    @EnvironmentObject var coordinator: ApplicationCoordinator
    @State private var diagnosticsReport: String = "加载中..."
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 系统状态概览
                    systemOverviewSection
                    
                    // 详细诊断报告
                    diagnosticsReportSection
                }
                .padding()
            }
            .navigationTitle("系统诊断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        Task {
                            await loadDiagnosticsReport()
                        }
                    }
                }
            }
        }
        .task {
            await loadDiagnosticsReport()
        }
    }
    
    private var systemOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("系统概览")
                .font(.headline)
                .padding(.bottom, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statusCard("应用状态", "\(coordinator.applicationState)", getStateColor())
                statusCard("整体健康", coordinator.systemHealth.status, getHealthColor())
                statusCard("Actor系统", coordinator.systemHealth.actorSystemHealthy ? "正常" : "异常", coordinator.systemHealth.actorSystemHealthy ? .green : .red)
                statusCard("事件系统", coordinator.systemHealth.eventSystemHealthy ? "正常" : "异常", coordinator.systemHealth.eventSystemHealthy ? .green : .red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var diagnosticsReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("详细诊断报告")
                    .font(.headline)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.bottom, 4)
            
            ScrollView {
                Text(diagnosticsReport)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .frame(height: 400)
            
            // 导出按钮
            HStack {
                Button(action: exportReport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出报告")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: copyReport) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("复制到剪贴板")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statusCard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func getStateColor() -> Color {
        switch coordinator.applicationState {
        case .ready: return .green
        case .degraded: return .orange
        case .error: return .red
        case .initializing: return .blue
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
    
    private func loadDiagnosticsReport() async {
        isLoading = true
        diagnosticsReport = await coordinator.getCompleteDiagnosticsReport()
        isLoading = false
    }
    
    private func exportReport() {
        // 实现报告导出功能
        let activityViewController = UIActivityViewController(
            activityItems: [diagnosticsReport],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func copyReport() {
        UIPasteboard.general.string = diagnosticsReport
    }
}

#Preview {
    DiagnosticsView()
        .environmentObject(ApplicationCoordinator())
}