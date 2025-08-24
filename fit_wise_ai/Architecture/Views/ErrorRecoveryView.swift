//
//  ErrorRecoveryView.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import SwiftUI

/**
 * 错误恢复视图
 * 
 * 当系统遇到关键错误时显示，提供错误信息和恢复选项
 */
struct ErrorRecoveryView: View {
    let error: CriticalError?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 错误图标
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // 错误信息
            VStack(spacing: 12) {
                Text("系统遇到错误")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("未知错误")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // 错误详情
            if let error = error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("错误详情")
                        .font(.headline)
                    
                    Text(getErrorDetails(error))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // 恢复选项
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新启动")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // 可以在这里添加发送错误报告的功能
                }) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("发送错误报告")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
            
            // 技术信息
            VStack(spacing: 4) {
                Text("如果问题持续存在，请联系技术支持")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                
                Text("错误代码: \(getErrorCode())")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func getErrorDetails(_ error: CriticalError) -> String {
        switch error {
        case .initializationFailed(let detail):
            return """
            错误类型: 初始化失败
            详细信息: \(detail)
            时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))
            
            可能原因:
            • 系统资源不足
            • 权限配置问题
            • 网络连接异常
            """
            
        case .systemFailure(let detail):
            return """
            错误类型: 系统故障
            详细信息: \(detail)
            时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))
            
            可能原因:
            • 服务组件异常
            • Actor系统故障
            • 内存资源不足
            """
        }
    }
    
    private func getErrorCode() -> String {
        guard let error = error else { return "UNKNOWN_ERROR" }
        
        switch error {
        case .initializationFailed:
            return "INIT_FAILED_001"
        case .systemFailure:
            return "SYS_FAILURE_002"
        }
    }
}

#Preview {
    ErrorRecoveryView(
        error: .initializationFailed("Actor系统启动失败"),
        onRetry: {
            print("重试...")
        }
    )
}