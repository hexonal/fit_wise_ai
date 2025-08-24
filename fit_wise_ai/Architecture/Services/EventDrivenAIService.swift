//
//  EventDrivenAIService.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import OSLog
import Combine

// MARK: - 消息类型定义

struct GenerateAIAdviceMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "GenerateAIAdvice"
    let requestType: AIRequestType
    let inputData: AIInputDataSnapshot
    let requestedCategories: [String]?
}

struct GenerateWeeklyAdviceMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "GenerateWeeklyAdvice"
    let weeklyData: [HealthDataSnapshot]
    let preferences: [String: String]
}

struct UpdateAIConfigurationMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "UpdateAIConfiguration"
    let configKey: String
    let configValue: String
}

struct GetAIAdviceHistoryMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "GetAIAdviceHistory"
    let limit: Int?
    let category: String?
}

struct EvaluateAdviceQualityMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "EvaluateAdviceQuality"
    let adviceId: UUID
    let userFeedback: Double
    let contextData: [String: String]
}

// MARK: - 响应类型定义

struct AIAdviceResponse: Sendable {
    let advice: [AIAdviceSnapshot]
    let generationTime: TimeInterval
    let generationMethod: AIGenerationMethod
}

struct WeeklyAdviceResponse: Sendable {
    let weeklyAdvice: [AIAdviceSnapshot]
    let trends: [String: String]
    let improvements: [String]
}

struct AIConfigurationResponse: Sendable {
    let success: Bool
    let configKey: String
    let previousValue: String?
    let newValue: String
}

struct AIAdviceHistoryResponse: Sendable {
    let history: [AIAdviceSnapshot]
    let totalCount: Int
    let hasMore: Bool
}

struct AdviceQualityResponse: Sendable {
    let adviceId: UUID
    let qualityScore: Double
    let recommendations: [String]
}

/**
 * 事件驱动的AI服务
 * 
 * 重构后的AI服务，完全基于事件驱动架构：
 * - 所有AI操作都通过事件记录
 * - 与AIActor协同工作
 * - 支持多种AI生成策略
 * - 提供智能降级和容错机制
 */
@MainActor
class EventDrivenAIService: ObservableObject {
    
    // MARK: - Properties
    
    /// 事件总线引用
    private let eventBus = EventBus.shared
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "EventDrivenAIService")
    /// AIActor引用
    private var aiActor: AIActor?
    /// 网络服务实例
    private let networkService = NetworkService()
    
    /// 当前服务状态
    @Published private(set) var currentState: AIServiceState = .uninitialized
    /// 最新生成的建议
    @Published private(set) var latestAdvice: [AIAdviceSnapshot] = []
    /// 生成历史
    @Published private(set) var adviceHistory: [AIAdviceSnapshot] = []
    /// AI配置
    @Published private(set) var configuration: AIServiceConfiguration = AIServiceConfiguration()
    /// 性能统计
    @Published private(set) var performanceStats: AIPerformanceStats = AIPerformanceStats()
    /// 错误状态
    @Published private(set) var lastError: Error?
    
    /// 取消订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        logger.info("EventDrivenAIService initializing")
        setupEventSubscriptions()
        initializeService()
    }
    
    deinit {
        logger.info("EventDrivenAIService deinitialized")
    }
    
    // MARK: - Service Initialization
    
    private func initializeService() {
        Task {
            await transitionTo(.initializing)
            
            // 加载配置
            loadConfiguration()
            
            // 注册AIActor
            aiActor = AIActor()
            if let actor = aiActor {
                await ActorSystem.shared.register(actor)
            }
            
            await transitionTo(.ready)
            logger.info("EventDrivenAIService initialized successfully")
        }
    }
    
    // MARK: - Event Subscriptions
    
    private func setupEventSubscriptions() {
        // 订阅AI建议请求事件
        eventBus.subscribe(to: AIAdviceRequestedEvent.self) { [weak self] event in
            await self?.handleAdviceRequestedEvent(event)
            return .success
        }
        
        // 订阅AI建议生成完成事件
        eventBus.subscribe(to: AIAdviceGeneratedEvent.self) { [weak self] event in
            await self?.handleAdviceGeneratedEvent(event)
            return .success
        }
        
        // 订阅AI建议生成失败事件
        eventBus.subscribe(to: AIAdviceGenerationFailedEvent.self) { [weak self] event in
            await self?.handleAdviceGenerationFailedEvent(event)
            return .success
        }
        
        // 订阅API调用事件
        eventBus.subscribe(to: AIAPICallCompletedEvent.self) { [weak self] event in
            await self?.handleAPICallCompletedEvent(event)
            return .success
        }
        
        eventBus.subscribe(to: AIAPICallFailedEvent.self) { [weak self] event in
            await self?.handleAPICallFailedEvent(event)
            return .success
        }
        
        // 订阅健康数据更新事件（自动生成建议）
        eventBus.subscribe(to: HealthDataUpdatedEvent.self) { [weak self] event in
            await self?.handleHealthDataUpdatedEvent(event)
            return .success
        }
        
        logger.info("AI service event subscriptions set up")
    }
    
    // MARK: - State Management
    
    private func transitionTo(_ newState: AIServiceState) async {
        let previousState = currentState
        currentState = newState
        
        logger.info("AI Service state transition: \(previousState) -> \(newState)")
        
        // 发布状态变化事件
        await eventBus.publish(DefaultEvent(
            eventType: "AIServiceStateChanged",
            source: "EventDrivenAIService",
            metadata: [
                "previousState": String(describing: previousState),
                "newState": String(describing: newState)
            ]
        ))
    }
    
    // MARK: - Public Interface
    
    /**
     * 生成AI建议
     */
    func generateAdvice(from healthData: HealthData) async -> [AIAdviceSnapshot] {
        guard currentState == .ready else {
            logger.warning("AI Service not ready for advice generation")
            return []
        }
        
        await transitionTo(.generating)
        
        do {
            if let actor = aiActor {
                let inputData = AIInputDataSnapshot(
                    healthData: HealthDataSnapshot(from: healthData),
                    context: ["trigger": "manual_request"]
                )
                
                let message = GenerateAIAdviceMessage(
                    requestType: .dailyAdvice,
                    inputData: inputData,
                    requestedCategories: nil
                )
                
                let response: AIAdviceResponse = try await actor.ask(message)
                
                latestAdvice = response.advice
                adviceHistory.append(contentsOf: response.advice)
                
                // 更新性能统计
                performanceStats.recordSuccessfulGeneration(
                    duration: response.generationTime,
                    method: response.generationMethod,
                    adviceCount: response.advice.count
                )
                
                await transitionTo(.ready)
                return response.advice
            } else {
                throw AIServiceError.actorNotAvailable
            }
            
        } catch {
            logger.error("Failed to generate AI advice: \(error)")
            lastError = error
            performanceStats.recordFailedGeneration()
            await transitionTo(.error(error))
            return []
        }
    }
    
    /**
     * 生成周建议
     */
    func generateWeeklyAdvice(from weeklyData: [HealthData]) async -> [AIAdviceSnapshot] {
        guard currentState == .ready else {
            logger.warning("AI Service not ready for weekly advice generation")
            return []
        }
        
        await transitionTo(.generating)
        
        do {
            if let actor = aiActor {
                let historicalSnapshots = weeklyData.map { HealthDataSnapshot(from: $0) }
                
                let message = GenerateWeeklyAdviceMessage(
                    weeklyData: historicalSnapshots,
                    preferences: getUserPreferences()
                )
                
                let response: WeeklyAdviceResponse = try await actor.ask(message)
                
                latestAdvice = response.weeklyAdvice
                adviceHistory.append(contentsOf: response.weeklyAdvice)
                
                // 更新性能统计
                performanceStats.recordSuccessfulGeneration(
                    duration: 1.0,
                    method: .hybridApproach, // 周建议通常使用混合方法
                    adviceCount: response.weeklyAdvice.count
                )
                
                await transitionTo(.ready)
                return response.weeklyAdvice
            } else {
                throw AIServiceError.actorNotAvailable
            }
            
        } catch {
            logger.error("Failed to generate weekly AI advice: \(error)")
            lastError = error
            performanceStats.recordFailedGeneration()
            await transitionTo(.error(error))
            return []
        }
    }
    
    /**
     * 更新AI配置
     */
    func updateConfiguration(_ key: String, value: String) async -> Bool {
        do {
            if let actor = aiActor {
                let message = UpdateAIConfigurationMessage(
                    configKey: key,
                    configValue: value
                )
                
                let response: AIConfigurationResponse = try await actor.ask(message)
                
                if response.success {
                    // 更新本地配置
                    configuration.updateValue(value, forKey: key)
                    logger.info("AI configuration updated: \(key) = \(value)")
                    return true
                }
            }
        } catch {
            logger.error("Failed to update AI configuration: \(error)")
            lastError = error
        }
        return false
    }
    
    /**
     * 获取建议历史
     */
    func getAdviceHistory(dateRange: DateInterval? = nil, category: String? = nil) async -> [AIAdviceSnapshot] {
        do {
            if let actor = aiActor {
                let message = GetAIAdviceHistoryMessage(
                    limit: 100,
                    category: category
                )
                
                let response: AIAdviceHistoryResponse = try await actor.ask(message)
                return response.history
            }
        } catch {
            logger.error("Failed to get advice history: \(error)")
        }
        return []
    }
    
    /**
     * 评估建议质量
     */
    func evaluateAdviceQuality(adviceId: UUID, feedback: String, rating: Int) async -> Bool {
        do {
            if let actor = aiActor {
                let message = EvaluateAdviceQualityMessage(
                    adviceId: adviceId,
                    userFeedback: Double(rating),
                    contextData: ["feedback": feedback]
                )
                
                let response: AdviceQualityResponse = try await actor.ask(message)
                
                if response.qualityScore > 0 {
                    logger.info("Advice quality updated: \(adviceId) rated \(rating)/5")
                    return true
                }
            }
        } catch {
            logger.error("Failed to evaluate advice quality: \(error)")
        }
        return false
    }
    
    // MARK: - Event Handlers
    
    private func handleAdviceRequestedEvent(_ event: AIAdviceRequestedEvent) async {
        logger.info("AI advice requested: \(event.requestType.rawValue)")
        
        // 可以在这里添加请求前的准备工作
        // 例如：检查网络状态、预加载必要数据等
        
        if event.requestType == .realTimeAdvice {
            await transitionTo(.generating)
        }
    }
    
    private func handleAdviceGeneratedEvent(_ event: AIAdviceGeneratedEvent) async {
        logger.info("AI advice generated: \(event.generatedAdvice.count) pieces via \(event.generationMethod.rawValue)")
        
        // 更新本地状态
        if event.source == "AIActor" {
            latestAdvice = event.generatedAdvice
            // 只添加新的建议到历史记录（避免重复）
            let newAdvice = event.generatedAdvice.filter { newItem in
                !adviceHistory.contains { existing in existing.id == newItem.id }
            }
            adviceHistory.append(contentsOf: newAdvice)
        }
        
        // 更新统计
        performanceStats.recordSuccessfulGeneration(
            duration: event.generationDuration,
            method: event.generationMethod,
            adviceCount: event.generatedAdvice.count
        )
        
        // 如果之前是生成状态，转回就绪状态
        if currentState == .generating {
            await transitionTo(.ready)
        }
    }
    
    private func handleAdviceGenerationFailedEvent(_ event: AIAdviceGenerationFailedEvent) async {
        logger.error("AI advice generation failed: \(event.error)")
        
        lastError = NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: event.error])
        performanceStats.recordFailedGeneration()
        
        // 如果有降级建议，使用它们
        if let fallbackAdvice = event.fallbackAdvice, !fallbackAdvice.isEmpty {
            latestAdvice = fallbackAdvice
            adviceHistory.append(contentsOf: fallbackAdvice)
            logger.info("Using fallback advice: \(fallbackAdvice.count) pieces")
            await transitionTo(.ready)
        } else {
            await transitionTo(.error(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: event.error])))
        }
    }
    
    private func handleAPICallCompletedEvent(_ event: AIAPICallCompletedEvent) async {
        logger.info("AI API call completed: \(event.statusCode) in \(String(format: "%.2f", event.duration * 1000))ms")
        
        performanceStats.recordAPICall(
            duration: event.duration,
            success: event.statusCode == 200
        )
    }
    
    private func handleAPICallFailedEvent(_ event: AIAPICallFailedEvent) async {
        logger.error("AI API call failed: \(event.error)")
        
        performanceStats.recordAPICall(
            duration: 0,
            success: false
        )
        
        // 如果是网络错误且启用了自动降级，切换到离线模式
        if event.error.lowercased().contains("network") && configuration.autoFallbackEnabled {
            logger.info("Switching to offline mode due to network error")
            // 这里可以临时禁用API模式，只使用规则引擎
        }
    }
    
    private func handleHealthDataUpdatedEvent(_ event: HealthDataUpdatedEvent) async {
        // 如果启用了自动建议生成
        guard configuration.autoGenerateEnabled else { return }
        
        // 检查数据变化是否足够显著
        let significantChanges = ["steps", "activeEnergyBurned", "workoutTime"]
        let hasSignificantChange = event.changedFields.contains { significantChanges.contains($0) }
        
        if hasSignificantChange {
            logger.info("Significant health data change detected, auto-generating advice")
            
            let healthData = event.currentData.toHealthData()
            let _ = await generateAdvice(from: healthData)
        }
    }
    
    // MARK: - Configuration Management
    
    private func loadConfiguration() {
        // 从UserDefaults或其他存储加载配置
        let defaults = UserDefaults.standard
        
        configuration = AIServiceConfiguration(
            apiKey: defaults.string(forKey: "ai_api_key") ?? "",
            model: defaults.string(forKey: "ai_model") ?? "gpt-3.5-turbo",
            temperature: defaults.double(forKey: "ai_temperature") != 0 ? defaults.double(forKey: "ai_temperature") : 0.7,
            maxTokens: defaults.integer(forKey: "ai_max_tokens") != 0 ? defaults.integer(forKey: "ai_max_tokens") : 800,
            autoGenerateEnabled: defaults.bool(forKey: "ai_auto_generate"),
            autoFallbackEnabled: defaults.bool(forKey: "ai_auto_fallback")
        )
        
        logger.info("AI service configuration loaded")
    }
    
    private func getUserPreferences() -> [String: String] {
        // 从存储中获取用户偏好
        return [
            "preferred_advice_style": "concise",
            "preferred_categories": "exercise,nutrition,rest",
            "language": "zh"
        ]
    }
    
    // MARK: - Diagnostics and Monitoring
    
    /**
     * 获取服务状态报告
     */
    func getStatusReport() -> AIServiceStatusReport {
        return AIServiceStatusReport(
            currentState: currentState,
            isActorConnected: aiActor != nil,
            configuration: configuration,
            performanceStats: performanceStats,
            adviceHistoryCount: adviceHistory.count,
            lastAdviceGeneratedAt: latestAdvice.first?.createdAt,
            lastError: lastError
        )
    }
    
    /**
     * 执行AI服务诊断
     */
    func performDiagnostics() async -> String {
        var report = "🤖 EventDriven AI Service 诊断报告\n\n"
        
        // 基本状态
        report += "🔍 基本状态\n"
        report += "   服务状态: \(currentState)\n"
        report += "   Actor连接: \(aiActor != nil ? "已连接" : "未连接")\n"
        report += "   网络状态: \(networkService.isConnected ? "已连接" : "未连接")\n\n"
        
        // 配置信息
        report += "⚙️ 配置信息\n"
        report += "   API密钥: \(configuration.apiKey.isEmpty ? "未配置" : "已配置")\n"
        report += "   AI模型: \(configuration.model)\n"
        report += "   温度参数: \(configuration.temperature)\n"
        report += "   最大Token: \(configuration.maxTokens)\n"
        report += "   自动生成: \(configuration.autoGenerateEnabled ? "启用" : "禁用")\n"
        report += "   自动降级: \(configuration.autoFallbackEnabled ? "启用" : "禁用")\n\n"
        
        // 性能统计
        report += "📊 性能统计\n"
        report += "   总生成次数: \(performanceStats.totalGenerations)\n"
        report += "   成功生成数: \(performanceStats.successfulGenerations)\n"
        report += "   成功率: \(String(format: "%.1f", performanceStats.successRate * 100))%\n"
        report += "   平均生成时间: \(String(format: "%.2f", performanceStats.averageGenerationTime * 1000))ms\n"
        report += "   API调用次数: \(performanceStats.totalAPICallCount)\n"
        report += "   API成功率: \(String(format: "%.1f", performanceStats.apiSuccessRate * 100))%\n\n"
        
        // 建议历史
        report += "📝 建议历史\n"
        report += "   历史记录数量: \(adviceHistory.count)\n"
        report += "   最新建议数量: \(latestAdvice.count)\n"
        if let lastAdvice = latestAdvice.first {
            report += "   最后生成时间: \(DateFormatter.localizedString(from: lastAdvice.createdAt, dateStyle: .medium, timeStyle: .short))\n"
            report += "   最后建议类别: \(lastAdvice.category)\n"
        }
        report += "\n"
        
        // 生成方法统计
        report += "🔄 生成方法统计\n"
        let methodStats = performanceStats.generationMethodStats
        for (method, count) in methodStats {
            let percentage = performanceStats.totalGenerations > 0 ? Double(count) / Double(performanceStats.totalGenerations) * 100 : 0
            report += "   \(method.rawValue): \(count)次 (\(String(format: "%.1f", percentage))%)\n"
        }
        report += "\n"
        
        // Actor状态
        if let actor = aiActor {
            let actorStats = await actor.getStatistics()
            report += "🎭 Actor统计\n"
            report += "   处理消息数: \(actorStats.messagesProcessed)\n"
            report += "   队列中消息: \(actorStats.messagesQueued)\n"
            report += "   平均处理时间: \(String(format: "%.2f", actorStats.averageProcessingTime * 1000))ms\n"
            report += "   错误数量: \(actorStats.errorCount)\n"
        }
        
        // 错误信息
        if let error = lastError {
            report += "\n❌ 最后错误\n"
            report += "   错误信息: \(error.localizedDescription)\n"
        }
        
        return report
    }
}

// MARK: - Supporting Types

/**
 * AI服务状态枚举
 */
enum AIServiceState: CustomStringConvertible {
    case uninitialized          // 未初始化
    case initializing           // 初始化中
    case ready                  // 就绪
    case generating             // 生成建议中
    case error(Error)          // 错误状态
    
    var description: String {
        switch self {
        case .uninitialized: return "未初始化"
        case .initializing: return "初始化中"
        case .ready: return "就绪"
        case .generating: return "生成中"
        case .error(let error): return "错误: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: AIServiceState, rhs: AIServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized), (.initializing, .initializing),
             (.ready, .ready), (.generating, .generating):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/**
 * AI服务错误类型
 */
enum AIServiceError: Error, LocalizedError {
    case actorNotAvailable
    case serviceNotReady
    case configurationInvalid
    case adviceGenerationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .actorNotAvailable:
            return "AI Actor not available"
        case .serviceNotReady:
            return "AI service is not ready"
        case .configurationInvalid:
            return "AI service configuration is invalid"
        case .adviceGenerationFailed(let error):
            return "Advice generation failed: \(error.localizedDescription)"
        }
    }
}

/**
 * AI服务配置
 */
struct AIServiceConfiguration {
    var apiKey: String = ""
    var model: String = "gpt-3.5-turbo"
    var temperature: Double = 0.7
    var maxTokens: Int = 800
    var autoGenerateEnabled: Bool = false
    var autoFallbackEnabled: Bool = true
    
    mutating func updateValue(_ value: String, forKey key: String) {
        switch key {
        case "api_key": apiKey = value
        case "model": model = value
        case "temperature": temperature = Double(value) ?? 0.7
        case "max_tokens": maxTokens = Int(value) ?? 800
        case "auto_generate": autoGenerateEnabled = Bool(value) ?? false
        case "auto_fallback": autoFallbackEnabled = Bool(value) ?? true
        default: break
        }
    }
}

/**
 * AI性能统计
 */
struct AIPerformanceStats {
    var totalGenerations: Int = 0
    var successfulGenerations: Int = 0
    var totalGenerationTime: TimeInterval = 0
    var totalAPICallCount: Int = 0
    var successfulAPICallCount: Int = 0
    var totalAPICallTime: TimeInterval = 0
    var generationMethodStats: [AIGenerationMethod: Int] = [:]
    
    var successRate: Double {
        guard totalGenerations > 0 else { return 0 }
        return Double(successfulGenerations) / Double(totalGenerations)
    }
    
    var averageGenerationTime: TimeInterval {
        guard successfulGenerations > 0 else { return 0 }
        return totalGenerationTime / Double(successfulGenerations)
    }
    
    var apiSuccessRate: Double {
        guard totalAPICallCount > 0 else { return 0 }
        return Double(successfulAPICallCount) / Double(totalAPICallCount)
    }
    
    var averageAPICallTime: TimeInterval {
        guard successfulAPICallCount > 0 else { return 0 }
        return totalAPICallTime / Double(successfulAPICallCount)
    }
    
    mutating func recordSuccessfulGeneration(duration: TimeInterval, method: AIGenerationMethod, adviceCount: Int) {
        totalGenerations += 1
        successfulGenerations += 1
        totalGenerationTime += duration
        generationMethodStats[method, default: 0] += 1
    }
    
    mutating func recordFailedGeneration() {
        totalGenerations += 1
    }
    
    mutating func recordAPICall(duration: TimeInterval, success: Bool) {
        totalAPICallCount += 1
        if success {
            successfulAPICallCount += 1
            totalAPICallTime += duration
        }
    }
}

/**
 * AI服务状态报告
 */
struct AIServiceStatusReport {
    let currentState: AIServiceState
    let isActorConnected: Bool
    let configuration: AIServiceConfiguration
    let performanceStats: AIPerformanceStats
    let adviceHistoryCount: Int
    let lastAdviceGeneratedAt: Date?
    let lastError: Error?
    
    var isHealthy: Bool {
        switch currentState {
        case .ready:
            return true
        default:
            return false
        }
    }
    
    var hasRecentAdvice: Bool {
        guard let timestamp = lastAdviceGeneratedAt else { return false }
        return Date().timeIntervalSince(timestamp) < 3600 // 1小时内的建议
    }
}