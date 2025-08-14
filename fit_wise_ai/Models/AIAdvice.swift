//
//  AIAdvice.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation

/**
 * AI 建议数据模型
 * 
 * 表示基于用户健康数据生成的个性化建议
 * 包含建议的标题、内容、分类、创建时间和优先级
 */
struct AIAdvice: Identifiable, Codable {
    /// 唯一标识符
    let id = UUID()
    /// 建议标题
    let title: String
    /// 建议详细内容
    let content: String
    /// 建议分类
    let category: AdviceCategory
    /// 创建时间
    let createdAt: Date
    /// 建议优先级
    let priority: AdvicePriority
    
    /**
     * 初始化方法
     * 
     * - Parameters:
     *   - title: 建议标题
     *   - content: 建议详细内容
     *   - category: 建议分类
     *   - priority: 建议优先级，默认为中等优先级
     */
    init(title: String, 
         content: String, 
         category: AdviceCategory, 
         priority: AdvicePriority = .medium) {
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
        self.priority = priority
    }
}

/**
 * 建议分类枚举
 * 
 * 定义不同类型的健康建议分类
 * 每个分类都有对应的图标和颜色主题
 */
enum AdviceCategory: String, CaseIterable, Codable {
    /// 运动相关建议
    case exercise = "运动建议"
    /// 休息相关建议
    case rest = "休息建议" 
    /// 营养相关建议
    case nutrition = "营养建议"
    /// 综合性建议
    case general = "综合建议"
    
    /**
     * 分类对应的 SF Symbols 图标名称
     */
    var icon: String {
        switch self {
        case .exercise:
            return "figure.run"      // 跑步图标
        case .rest:
            return "bed.double"      // 床铺图标
        case .nutrition:
            return "leaf"            // 叶子图标（代表营养）
        case .general:
            return "lightbulb"       // 灯泡图标（代表建议）
        }
    }
    
    /**
     * 分类对应的颜色主题
     * 返回在 Assets.xcassets 中定义的颜色名称
     */
    var color: String {
        switch self {
        case .exercise:
            return "blue"            // 蓝色主题
        case .rest:
            return "purple"          // 紫色主题
        case .nutrition:
            return "green"           // 绿色主题
        case .general:
            return "orange"          // 橙色主题
        }
    }
}

/**
 * 建议优先级枚举
 * 
 * 定义建议的重要程度级别
 * 用于帮助用户识别哪些建议需要优先关注
 */
enum AdvicePriority: String, Codable {
    /// 低优先级建议
    case low = "低"
    /// 中等优先级建议（默认值）
    case medium = "中"
    /// 高优先级建议
    case high = "高"
    /// 紧急建议，需要立即关注
    case urgent = "紧急"
}