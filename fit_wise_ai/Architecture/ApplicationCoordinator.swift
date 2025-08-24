//
//  ApplicationCoordinator.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import SwiftUI
import OSLog
import Combine

/**
 * 应用程序协调器
 * 
 * 新架构的核心协调组件，负责：
 * - 初始化和协调所有Actor和服务
 * - 管理应用程序生命周期
 * - 处理跨组件的交互
 * - 提供统一的错误处理和恢复机制
 */
@MainActor
class ApplicationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 应用程序状态
    @Published private(set) var applicationState: ApplicationState = .initializing
    /// 系统健康状态
    @Published private(set) var systemHealth: SystemHealthStatus = SystemHealthStatus()
    /// 初始化进度
    @Published private(set) var initializationProgress: Double = 0.0
    /// 错误状态
    @Published private(set) var criticalError: CriticalError?
    
    // MARK: - Core Components
    
    /// Actor系统
    private let actorSystem = ActorSystem.shared
    /// 事件总线
    private let eventBus = EventBus.shared
    /// 事件存储
    private let eventStore = EventStore.shared
    /// 健康状态机
    private let healthStateMachine = HealthStateMachine()
    /// 服务集合
    private var services: [String: any AppService] = [:]
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "ApplicationCoordinator")
    /// 订阅管理
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Legacy Services (for backward compatibility)
    
    /// 传统HealthKitService（用于向后兼容）
    @Published var healthKitService = HealthKitService()
    /// 传统AIService（用于向后兼容）  
    @Published var aiService = AIService()
    
    // MARK: - Initialization
    
    init() {
        logger.info("ApplicationCoordinator initializing")
        setupEventSubscriptions()
        Task {
            await initializeApplication()
        }
    }
    
    // MARK: - Application Lifecycle
    
    /**
     * 初始化应用程序
     */
    private func initializeApplication() async {
        logger.info("Starting application initialization")
        
        await updateInitializationProgress(0.0, "开始初始化...")
        
        do {
            // 步骤1: 初始化事件系统 (20%)
            await updateInitializationProgress(0.2, "初始化事件系统...")
            try await initializeEventSystem()
            
            // 步骤2: 初始化状态机 (40%)
            await updateInitializationProgress(0.4, "初始化状态机...")
            try await initializeStateMachine()
            
            // 步骤3: 初始化核心服务 (60%)
            await updateInitializationProgress(0.6, "初始化核心服务...")
            try await initializeCoreServices()
            
            // 步骤4: 初始化Actor系统 (80%)
            await updateInitializationProgress(0.8, "初始化Actor系统...")
            try await initializeActorSystem()
            
            // 步骤5: 启动监控和诊断 (90%)
            await updateInitializationProgress(0.9, "启动监控系统...")
            try await startMonitoringSystem()
            
            // 步骤6: 完成初始化 (100%)
            await updateInitializationProgress(1.0, "初始化完成")
            await transitionToState(.ready)
            
            logger.info("Application initialization completed successfully")
            
        } catch {
            logger.error("Application initialization failed: \(error)")
            criticalError = CriticalError.initializationFailed(error.localizedDescription)
            await transitionToState(.error)
        }
    }
    
    private func initializeEventSystem() async throws {
        logger.info("Initializing event system")
        
        // 事件系统已经是单例，这里主要是验证其工作状态
        let stats = await eventStore.getEventStatistics()
        logger.info("Event store initialized with \(stats.totalEvents) existing events")
        
        // 发布应用程序启动事件
        await eventBus.publish(DefaultEvent(
            eventType: "ApplicationInitializationStarted",
            source: "ApplicationCoordinator",
            metadata: [
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            ]
        ))
    }
    
    private func initializeStateMachine() async throws {
        logger.info("Initializing state machine")
        
        // 启动健康状态机
        let success = await healthStateMachine.handle(.initialize)
        if !success {
            throw CoordinatorError.stateMachineInitializationFailed
        }
        
        logger.info("State machine initialized successfully")
    }
    
    private func initializeCoreServices() async throws {
        logger.info("Initializing core services")
        
        // 初始化健康服务
        let healthService = EventDrivenHealthKitService()
        services["health"] = healthService
        
        // 初始化AI服务
        let aiService = EventDrivenAIService()
        services["ai"] = aiService
        
        // 等待服务就绪
        try await waitForServicesReady(timeout: 30.0)
        
        logger.info("Core services initialized successfully")
    }
    
    private func initializeActorSystem() async throws {
        logger.info("Initializing actor system")
        
        // Actor在服务初始化时已经被注册
        // 这里验证所有Actor都正常工作
        let stats = actorSystem.getSystemStatistics()
        let totalActors = stats["totalActors"] as? Int ?? 0
        
        if totalActors == 0 {
            throw CoordinatorError.actorSystemInitializationFailed
        }
        
        logger.info("Actor system initialized with \(totalActors) actors")
    }
    
    private func startMonitoringSystem() async throws {
        logger.info("Starting monitoring system")
        
        // 启动周期性健康检查
        startPeriodicHealthCheck()
        
        // 启动性能监控
        startPerformanceMonitoring()
        
        logger.info("Monitoring system started")
    }
    
    // MARK: - Event Subscriptions
    
    private func setupEventSubscriptions() {
        // 订阅关键事件来更新系统状态
        
        // 健康相关事件
        eventBus.subscribe(to: HealthPermissionGrantedEvent.self) { [weak self] event in
            await self?.handleHealthPermissionGranted(event)
            return .success
        }
        
        eventBus.subscribe(to: HealthPermissionDeniedEvent.self) { [weak self] event in
            await self?.handleHealthPermissionDenied(event)
            return .success
        }
        
        eventBus.subscribe(to: HealthDataFetchCompletedEvent.self) { [weak self] event in
            await self?.handleHealthDataFetchCompleted(event)
            return .success
        }
        
        // AI相关事件
        eventBus.subscribe(to: AIAdviceGeneratedEvent.self) { [weak self] event in
            await self?.handleAIAdviceGenerated(event)
            return .success
        }
        
        // 错误事件
        eventBus.subscribeToAll { [weak self] event in
            await self?.handleGenericEvent(event)
            return .success
        }
        
        logger.info("Event subscriptions established")
    }
    
    // MARK: - State Management
    
    private func transitionToState(_ newState: ApplicationState) async {
        let previousState = applicationState
        applicationState = newState
        
        logger.info("Application state transition: \(previousState) -> \(newState)")
        
        // 发布状态变化事件
        await eventBus.publish(DefaultEvent(
            eventType: "ApplicationStateChanged",
            source: "ApplicationCoordinator",
            metadata: [
                "previousState": String(describing: previousState),
                "newState": String(describing: newState)
            ]
        ))
        
        // 根据新状态执行相应操作
        await onStateEnter(newState)
    }
    
    private func onStateEnter(_ state: ApplicationState) async {
        switch state {
        case .ready:
            await onApplicationReady()
        case .degraded:
            await onApplicationDegraded()
        case .error:
            await onApplicationError()
        default:
            break
        }
    }
    
    private func onApplicationReady() async {
        logger.info("Application is ready for use")
        
        // 可以在这里触发初始数据加载等操作
        if let healthService = services["health"] as? EventDrivenHealthKitService {
            // 请求权限（如果需要）
            let _ = await healthService.requestAuthorization()
        }
    }
    
    private func onApplicationDegraded() async {
        logger.warning("Application entered degraded mode")
        
        // 在降级模式下，可能需要禁用某些功能
        // 或者显示用户通知
    }
    
    private func onApplicationError() async {
        logger.error("Application entered error state")
        
        // 启动错误恢复机制
        await attemptErrorRecovery()
    }
    
    // MARK: - Health Monitoring
    
    private func startPeriodicHealthCheck() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }
    
    private func performHealthCheck() async {
        logger.debug("Performing periodic health check")
        
        // 检查Actor系统健康状态
        let actorStats = actorSystem.getSystemStatistics()
        let totalActors = actorStats["totalActors"] as? Int ?? 0
        
        // 检查事件系统健康状态
        let eventStats = await eventStore.getEventStatistics()
        
        // 检查状态机健康状态
        let stateMachineDiagnostics = await healthStateMachine.getDiagnostics()
        
        // 更新系统健康状态
        systemHealth = SystemHealthStatus(
            actorSystemHealthy: totalActors > 0,
            eventSystemHealthy: eventStats.totalEvents >= 0,
            stateMachineHealthy: stateMachineDiagnostics.isOperational,
            servicesHealthy: await checkServicesHealth(),
            overallScore: calculateOverallHealthScore(
                actorCount: totalActors,
                eventCount: eventStats.totalEvents,
                stateMachineScore: stateMachineDiagnostics.healthScore
            )
        )
        
        // 如果健康状态不佳，考虑状态转换
        if systemHealth.overallScore < 0.5 && applicationState == .ready {
            await transitionToState(.degraded)
        } else if systemHealth.overallScore > 0.8 && applicationState == .degraded {
            await transitionToState(.ready)
        }
    }
    
    private func checkServicesHealth() async -> Bool {
        for (name, service) in services {
            let isHealthy = await service.isHealthy()
            if !isHealthy {
                logger.warning("Service \(name) is not healthy")
                return false
            }
        }
        return true
    }
    
    private func calculateOverallHealthScore(actorCount: Int, eventCount: Int, stateMachineScore: Double) -> Double {
        var score = 0.0
        
        // Actor系统得分 (30%)
        score += actorCount > 0 ? 0.3 : 0.0
        
        // 事件系统得分 (20%)
        score += eventCount >= 0 ? 0.2 : 0.0
        
        // 状态机得分 (30%)
        score += stateMachineScore * 0.3
        
        // 服务得分 (20%) - 简化计算
        score += 0.2
        
        return min(1.0, max(0.0, score))
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.logPerformanceMetrics()
            }
        }
    }
    
    private func logPerformanceMetrics() async {
        logger.info("📊 Performance Metrics:")
        
        // Actor系统性能
        let actorStats = actorSystem.getSystemStatistics()
        if let actors = actorStats["actors"] as? [String: [String: Any]] {
            for (name, stats) in actors {
                let messages = stats["messagesProcessed"] as? Int ?? 0
                let avgTime = stats["averageProcessingTime"] as? Double ?? 0
                logger.info("  Actor \(name): \(messages) messages, avg \(String(format: "%.2f", avgTime))ms")
            }
        }
        
        // 事件系统性能
        let eventStats = await eventStore.getEventStatistics()
        logger.info("  Events: \(eventStats.totalEvents) total")
        
        // 内存使用情况
        let memoryUsage = getMemoryUsage()
        logger.info("  Memory: \(String(format: "%.1f", memoryUsage))MB")
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleHealthPermissionGranted(_ event: HealthPermissionGrantedEvent) async {
        logger.info("Health permission granted")
        let _ = await healthStateMachine.handle(.permissionGranted)
    }
    
    private func handleHealthPermissionDenied(_ event: HealthPermissionDeniedEvent) async {
        logger.warning("Health permission denied")
        let _ = await healthStateMachine.handle(.permissionDenied)
    }
    
    private func handleHealthDataFetchCompleted(_ event: HealthDataFetchCompletedEvent) async {
        logger.info("Health data fetch completed")
        let _ = await healthStateMachine.handle(.dataFetchCompleted)
    }
    
    private func handleAIAdviceGenerated(_ event: AIAdviceGeneratedEvent) async {
        logger.info("AI advice generated: \(event.generatedAdvice.count) pieces")
        // 可以在这里处理建议生成后的逻辑
    }
    
    private func handleGenericEvent(_ event: any BaseEvent) async {
        // 监控错误和异常事件
        if event.eventType.contains("Failed") || event.eventType.contains("Error") {
            logger.warning("Error event detected: \(event.eventType)")
            
            // 根据错误类型更新状态机
            if event.eventType.contains("HealthData") {
                let _ = await healthStateMachine.handle(.errorOccurred(.dataUnavailable))
            }
        }
    }
    
    // MARK: - Error Recovery
    
    private func attemptErrorRecovery() async {
        logger.info("Attempting application error recovery")
        
        // 重试初始化关键组件
        do {
            try await initializeCoreServices()
            await transitionToState(.ready)
            logger.info("Error recovery successful")
        } catch {
            logger.error("Error recovery failed: \(error)")
            await transitionToState(.degraded)
        }
    }
    
    // MARK: - Utility Methods
    
    private func updateInitializationProgress(_ progress: Double, _ message: String) async {
        initializationProgress = progress
        logger.info("Initialization progress: \(Int(progress * 100))% - \(message)")
    }
    
    private func waitForServicesReady(timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            var allReady = true
            for service in services.values {
                if !(await service.isReady()) {
                    allReady = false
                    break
                }
            }
            if allReady {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        throw CoordinatorError.serviceInitializationTimeout
    }
    
    // MARK: - Public Interface
    
    /**
     * 获取完整的系统诊断报告
     */
    func getCompleteDiagnosticsReport() async -> String {
        var report = "🏥 FitWise AI 完整系统诊断报告\n"
        report += "生成时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium))\n\n"
        
        // 应用程序状态
        report += "🚀 应用程序状态\n"
        report += "   当前状态: \(applicationState)\n"
        report += "   系统健康分数: \(String(format: "%.1f", systemHealth.overallScore * 100))%\n"
        report += "   初始化进度: \(String(format: "%.1f", initializationProgress * 100))%\n\n"
        
        // Actor系统
        let actorStats = actorSystem.getSystemStatistics()
        report += "🎭 Actor系统\n"
        report += "   总Actor数: \(actorStats["totalActors"] ?? 0)\n"
        if let actors = actorStats["actors"] as? [String: [String: Any]] {
            for (name, stats) in actors {
                report += "   \(name): \(stats["messagesProcessed"] ?? 0)条消息\n"
            }
        }
        report += "\n"
        
        // 事件系统
        let eventStats = await eventStore.getEventStatistics()
        report += "📊 事件系统\n"
        report += "   总事件数: \(eventStats.totalEvents)\n"
        report += "   事件类型数: \(eventStats.eventTypeCount.count)\n"
        if let timeSpan = eventStats.timeSpan {
            report += "   运行时长: \(String(format: "%.1f", timeSpan / 3600))小时\n"
        }
        report += "\n"
        
        // 状态机
        let stateMachineDiagnostics = await healthStateMachine.getDiagnostics()
        report += "🔄 健康状态机\n"
        report += "   当前状态: \(stateMachineDiagnostics.currentState)\n"
        report += "   健康分数: \(String(format: "%.1f", stateMachineDiagnostics.healthScore * 100))%\n"
        report += "   状态转换数: \(stateMachineDiagnostics.totalTransitions)\n"
        report += "\n"
        
        // 服务状态
        report += "⚙️ 服务状态\n"
        for (name, service) in services {
            let isHealthy = await service.isHealthy()
            let isReady = await service.isReady()
            report += "   \(name): \(isHealthy ? "健康" : "异常") | \(isReady ? "就绪" : "未就绪")\n"
        }
        
        return report
    }
    
    /**
     * 手动触发系统健康检查
     */
    func triggerHealthCheck() async {
        await performHealthCheck()
    }
    
    /**
     * 重置应用程序状态
     */
    func resetApplication() async {
        logger.info("Resetting application")
        
        await transitionToState(.initializing)
        criticalError = nil
        
        // 重新初始化
        await initializeApplication()
    }
}

// MARK: - Supporting Types

/**
 * 应用程序状态枚举
 */
enum ApplicationState: CustomStringConvertible {
    case initializing
    case ready
    case degraded
    case error
    
    var description: String {
        switch self {
        case .initializing: return "初始化中"
        case .ready: return "就绪"
        case .degraded: return "降级运行"
        case .error: return "错误状态"
        }
    }
}

/**
 * 关键错误类型
 */
enum CriticalError: Error, LocalizedError {
    case initializationFailed(String)
    case systemFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let detail): return "初始化失败: \(detail)"
        case .systemFailure(let detail): return "系统故障: \(detail)"
        }
    }
}

/**
 * 协调器错误类型
 */
enum CoordinatorError: Error {
    case stateMachineInitializationFailed
    case actorSystemInitializationFailed
    case serviceInitializationTimeout
}

/**
 * 系统健康状态
 */
struct SystemHealthStatus {
    var actorSystemHealthy: Bool = false
    var eventSystemHealthy: Bool = false
    var stateMachineHealthy: Bool = false
    var servicesHealthy: Bool = false
    var overallScore: Double = 0.0
    
    var status: String {
        switch overallScore {
        case 0.8...1.0: return "优秀"
        case 0.6...0.8: return "良好"
        case 0.4...0.6: return "一般"
        case 0.2...0.4: return "较差"
        default: return "危险"
        }
    }
}

/**
 * 应用服务协议
 */
protocol AppService {
    func isHealthy() async -> Bool
    func isReady() async -> Bool
}

// MARK: - Service Extensions

extension EventDrivenHealthKitService: AppService {
    func isHealthy() async -> Bool {
        return getStatusReport().isHealthy
    }
    
    func isReady() async -> Bool {
        switch currentState {
        case .ready, .authorized: return true
        default: return false
        }
    }
}

extension EventDrivenAIService: AppService {
    func isHealthy() async -> Bool {
        return getStatusReport().isHealthy
    }
    
    func isReady() async -> Bool {
        switch currentState {
        case .ready: return true
        default: return false
        }
    }
}