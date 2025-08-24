//
//  AIEvents.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation

/**
 * AI相关事件定义
 * 
 * 定义所有与AI服务相关的事件类型，包括建议生成、模型调用等
 */

// MARK: - AI建议生成事件

/// AI建议请求事件
struct AIAdviceRequestedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAdviceRequested"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 请求类型（今日建议、周建议等）
    let requestType: AIRequestType
    /// 输入数据快照
    let inputData: AIInputDataSnapshot
    /// 请求的建议类别
    let requestedCategories: [String]?
    
    init(
        requestType: AIRequestType,
        inputData: AIInputDataSnapshot,
        requestedCategories: [String]? = nil,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.requestType = requestType
        self.inputData = inputData
        self.requestedCategories = requestedCategories
        self.source = source
        self.metadata = metadata
    }
}

/// AI建议生成完成事件
struct AIAdviceGeneratedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAdviceGenerated"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 生成的建议列表
    let generatedAdvice: [AIAdviceSnapshot]
    /// 生成方式（API调用、离线规则等）
    let generationMethod: AIGenerationMethod
    /// 生成耗时（毫秒）
    let generationDuration: TimeInterval
    /// 使用的模型或规则版本
    let modelVersion: String?
    
    init(
        generatedAdvice: [AIAdviceSnapshot],
        generationMethod: AIGenerationMethod,
        generationDuration: TimeInterval,
        modelVersion: String? = nil,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.generatedAdvice = generatedAdvice
        self.generationMethod = generationMethod
        self.generationDuration = generationDuration
        self.modelVersion = modelVersion
        self.source = source
        self.metadata = metadata
    }
}

/// AI建议生成失败事件
struct AIAdviceGenerationFailedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAdviceGenerationFailed"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 错误信息
    let error: String
    /// 失败原因分类
    let failureReason: AIFailureReason
    /// 是否启用了降级策略
    let fallbackUsed: Bool
    /// 降级生成的建议（如果有）
    let fallbackAdvice: [AIAdviceSnapshot]?
    
    init(
        error: Error,
        failureReason: AIFailureReason,
        fallbackUsed: Bool = false,
        fallbackAdvice: [AIAdviceSnapshot]? = nil,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.error = error.localizedDescription
        self.failureReason = failureReason
        self.fallbackUsed = fallbackUsed
        self.fallbackAdvice = fallbackAdvice
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - AI模型调用事件

/// AI API调用开始事件
struct AIAPICallStartedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAPICallStarted"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// API端点
    let endpoint: String
    /// 使用的模型
    let model: String
    /// 请求参数摘要
    let requestSummary: String
    
    init(
        endpoint: String,
        model: String,
        requestSummary: String,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.endpoint = endpoint
        self.model = model
        self.requestSummary = requestSummary
        self.source = source
        self.metadata = metadata
    }
}

/// AI API调用完成事件
struct AIAPICallCompletedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAPICallCompleted"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 响应状态码
    let statusCode: Int
    /// 调用耗时（毫秒）
    let duration: TimeInterval
    /// 使用的token数量
    let tokenUsage: AITokenUsage?
    /// 响应内容摘要
    let responseSummary: String
    
    init(
        statusCode: Int,
        duration: TimeInterval,
        tokenUsage: AITokenUsage? = nil,
        responseSummary: String,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.statusCode = statusCode
        self.duration = duration
        self.tokenUsage = tokenUsage
        self.responseSummary = responseSummary
        self.source = source
        self.metadata = metadata
    }
}

/// AI API调用失败事件
struct AIAPICallFailedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIAPICallFailed"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 错误信息
    let error: String
    /// HTTP状态码（如果有）
    let statusCode: Int?
    /// 重试次数
    let retryCount: Int
    /// 是否会继续重试
    let willRetry: Bool
    
    init(
        error: Error,
        statusCode: Int? = nil,
        retryCount: Int,
        willRetry: Bool,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.error = error.localizedDescription
        self.statusCode = statusCode
        self.retryCount = retryCount
        self.willRetry = willRetry
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - AI配置事件

/// AI配置更新事件
struct AIConfigurationUpdatedEvent: BaseEvent {
    let id = UUID()
    let eventType = "AIConfigurationUpdated"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 配置项名称
    let configKey: String
    /// 旧值
    let previousValue: String?
    /// 新值
    let newValue: String
    
    init(
        configKey: String,
        previousValue: String?,
        newValue: String,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.configKey = configKey
        self.previousValue = previousValue
        self.newValue = newValue
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - 支持类型定义

/// AI请求类型
enum AIRequestType: String, Codable, CaseIterable {
    case dailyAdvice = "daily"
    case weeklyAdvice = "weekly"
    case realTimeAdvice = "realtime"
    case goalBasedAdvice = "goal_based"
}

/// AI生成方法
enum AIGenerationMethod: String, Codable, CaseIterable {
    case openaiAPI = "openai_api"
    case localModel = "local_model"
    case ruleBasedEngine = "rule_based"
    case hybridApproach = "hybrid"
}

/// AI失败原因
enum AIFailureReason: String, Codable, CaseIterable {
    case networkError = "network_error"
    case authenticationError = "auth_error"
    case quotaExceeded = "quota_exceeded"
    case invalidInput = "invalid_input"
    case serverError = "server_error"
    case configurationError = "config_error"
    case unknownError = "unknown_error"
}

/// AI输入数据快照
struct AIInputDataSnapshot: Codable, Sendable {
    /// 健康数据
    let healthData: HealthDataSnapshot?
    /// 历史数据（用于周建议）
    let historicalData: [HealthDataSnapshot]?
    /// 用户偏好设置
    let userPreferences: [String: String]?
    /// 上下文信息
    let context: [String: String]?
    
    init(
        healthData: HealthDataSnapshot? = nil,
        historicalData: [HealthDataSnapshot]? = nil,
        userPreferences: [String: String]? = nil,
        context: [String: String]? = nil
    ) {
        self.healthData = healthData
        self.historicalData = historicalData
        self.userPreferences = userPreferences
        self.context = context
    }
}

/// AI建议快照
struct AIAdviceSnapshot: Codable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let category: String
    let priority: String
    let createdAt: Date
    let confidence: Double?  // 0.0 - 1.0，建议的可信度
    let reasoning: String?   // AI生成建议的推理过程
    
    /// 从AIAdvice转换
    init(from advice: AIAdvice, confidence: Double? = nil, reasoning: String? = nil) {
        self.id = advice.id
        self.title = advice.title
        self.content = advice.content
        self.category = advice.category.rawValue
        self.priority = advice.priority.rawValue
        self.createdAt = advice.createdAt
        self.confidence = confidence
        self.reasoning = reasoning
    }
    
    /// 转换为AIAdvice
    func toAIAdvice() -> AIAdvice? {
        guard let category = AdviceCategory.allCases.first(where: { $0.rawValue == self.category }),
              let priority = AdvicePriority.allCases.first(where: { $0.rawValue == self.priority }) else {
            return nil
        }
        
        return AIAdvice(
            title: title,
            content: content,
            category: category,
            priority: priority
        )
    }
}

/// AI Token使用情况
struct AITokenUsage: Codable, Sendable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
    }
}