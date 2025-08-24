//
//  HealthStateMachine.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import OSLog
import Combine

/**
 * 健康状态机
 * 
 * 管理健康数据的复杂状态转换，确保系统在不同条件下的正确行为：
 * - 权限状态管理
 * - 数据获取状态流转
 * - 错误恢复机制
 * - 状态事件发布
 */
actor HealthStateMachine {
    
    // MARK: - State Definitions
    
    /// 健康状态枚举
    enum HealthState: Equatable, Hashable, CustomStringConvertible {
        case uninitialized                          // 未初始化
        case initializing                           // 初始化中
        case waitingForPermission                   // 等待权限
        case permissionDenied                       // 权限被拒绝
        case authorized                             // 已授权
        case fetchingInitialData                    // 获取初始数据
        case ready                                  // 就绪状态
        case fetchingData                           // 获取数据中
        case processingData                         // 数据处理中
        case error(HealthError)                     // 错误状态
        case recovering(from: HealthError)          // 错误恢复中
        case degraded(reason: String)               // 降级模式
        
        var description: String {
            switch self {
            case .uninitialized: return "未初始化"
            case .initializing: return "初始化中"
            case .waitingForPermission: return "等待权限"
            case .permissionDenied: return "权限被拒绝"
            case .authorized: return "已授权"
            case .fetchingInitialData: return "获取初始数据"
            case .ready: return "就绪"
            case .fetchingData: return "获取数据中"
            case .processingData: return "数据处理中"
            case .error(let error): return "错误: \(error.localizedDescription)"
            case .recovering(let error): return "从错误恢复: \(error.localizedDescription)"
            case .degraded(let reason): return "降级模式: \(reason)"
            }
        }
        
        var isOperational: Bool {
            switch self {
            case .ready, .fetchingData, .processingData, .degraded:
                return true
            default:
                return false
            }
        }
        
        var canFetchData: Bool {
            switch self {
            case .authorized, .ready, .degraded:
                return true
            default:
                return false
            }
        }
    }
    
    /// 健康状态机事件
    enum HealthEvent: CustomStringConvertible {
        case initialize
        case permissionRequested
        case permissionGranted
        case permissionDenied
        case startDataFetch
        case dataFetchCompleted
        case dataFetchFailed(HealthError)
        case dataProcessingStarted
        case dataProcessingCompleted
        case dataProcessingFailed(HealthError)
        case errorOccurred(HealthError)
        case recoveryAttempted
        case recoverySucceeded
        case recoveryFailed
        case degradeModeEntered(String)
        case reset
        
        var description: String {
            switch self {
            case .initialize: return "初始化"
            case .permissionRequested: return "权限请求"
            case .permissionGranted: return "权限授权"
            case .permissionDenied: return "权限拒绝"
            case .startDataFetch: return "开始数据获取"
            case .dataFetchCompleted: return "数据获取完成"
            case .dataFetchFailed(let error): return "数据获取失败: \(error)"
            case .dataProcessingStarted: return "数据处理开始"
            case .dataProcessingCompleted: return "数据处理完成"
            case .dataProcessingFailed(let error): return "数据处理失败: \(error)"
            case .errorOccurred(let error): return "错误发生: \(error)"
            case .recoveryAttempted: return "尝试恢复"
            case .recoverySucceeded: return "恢复成功"
            case .recoveryFailed: return "恢复失败"
            case .degradeModeEntered(let reason): return "进入降级模式: \(reason)"
            case .reset: return "重置"
            }
        }
    }
    
    /// 健康错误类型
    enum HealthError: Error, LocalizedError, Equatable, Hashable {
        case permissionDenied
        case dataUnavailable
        case networkError
        case processingError(String)
        case systemError(String)
        case recoveryTimeout
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "HealthKit权限被拒绝"
            case .dataUnavailable: return "健康数据不可用"
            case .networkError: return "网络连接错误"
            case .processingError(let detail): return "数据处理错误: \(detail)"
            case .systemError(let detail): return "系统错误: \(detail)"
            case .recoveryTimeout: return "恢复超时"
            }
        }
    }
    
    // MARK: - Properties
    
    /// 当前状态
    private(set) var currentState: HealthState = .uninitialized
    /// 状态历史
    private var stateHistory: [(state: HealthState, timestamp: Date)] = []
    /// 错误重试计数
    private var retryCount: [HealthError: Int] = [:]
    /// 最大重试次数
    private let maxRetries = 3
    /// 状态转换规则
    private let stateTransitionRules: [HealthState: Set<HealthState>]
    /// 事件总线
    nonisolated private let eventBus = EventBus.shared
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "HealthStateMachine")
    /// 恢复定时器
    private var recoveryTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // 简化状态转换规则
        self.stateTransitionRules = [
            .uninitialized: [.initializing],
            .initializing: [.waitingForPermission],
            .waitingForPermission: [.authorized, .permissionDenied],
            .permissionDenied: [.waitingForPermission],
            .authorized: [.ready],
            .ready: [.fetchingData, .processingData]
        ]
        
        logger.info("HealthStateMachine initialized")
    }
    
    // MARK: - State Management
    
    /**
     * 处理事件并转换状态
     */
    func handle(_ event: HealthEvent) async -> Bool {
        let previousState = currentState
        let newState = await processEvent(event, from: currentState)
        
        guard newState != currentState else {
            logger.debug("Event \(event) did not cause state change from \(self.currentState)")
            return false
        }
        
        // 验证状态转换是否合法
        guard isValidTransition(from: currentState, to: newState) else {
            logger.error("Invalid state transition: \(self.currentState) -> \(newState) via \(event)")
            return false
        }
        
        // 执行状态转换
        await transition(to: newState, via: event)
        
        logger.info("State transition: \(previousState) -> \(newState) via \(event)")
        return true
    }
    
    /**
     * 获取当前状态
     */
    func getCurrentState() -> HealthState {
        return currentState
    }
    
    /**
     * 获取状态历史
     */
    func getStateHistory(last count: Int = 10) -> [(state: HealthState, timestamp: Date)] {
        return Array(stateHistory.suffix(count))
    }
    
    /**
     * 检查是否可以执行特定操作
     */
    func canPerformOperation(_ operation: HealthOperation) -> Bool {
        switch operation {
        case .fetchData:
            return currentState.canFetchData
        case .processData:
            return currentState.isOperational
        case .requestPermission:
            switch currentState {
            case .uninitialized, .initializing, .waitingForPermission, .permissionDenied:
                return true
            default:
                return false
            }
        case .recover:
            switch currentState {
            case .error, .recovering:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Event Processing
    
    private func processEvent(_ event: HealthEvent, from state: HealthState) async -> HealthState {
        switch (event, state) {
        
        // 初始化流程
        case (.initialize, .uninitialized):
            return .initializing
            
        case (.permissionRequested, .initializing):
            return .waitingForPermission
            
        case (.permissionGranted, .waitingForPermission):
            return .authorized
            
        case (.permissionDenied, .waitingForPermission):
            return .permissionDenied
            
        // 数据获取流程
        case (.startDataFetch, .authorized):
            return .fetchingInitialData
            
        case (.startDataFetch, .ready):
            return .fetchingData
            
        case (.dataFetchCompleted, .fetchingInitialData):
            return .ready
            
        case (.dataFetchCompleted, .fetchingData):
            return .ready
            
        case (.dataFetchFailed(let error), .fetchingInitialData):
            return await handleDataFetchError(error, isInitial: true)
            
        case (.dataFetchFailed(let error), .fetchingData):
            return await handleDataFetchError(error, isInitial: false)
            
        // 数据处理流程
        case (.dataProcessingStarted, .ready):
            return .processingData
            
        case (.dataProcessingCompleted, .processingData):
            return .ready
            
        case (.dataProcessingFailed(let error), .processingData):
            return await handleProcessingError(error)
            
        // 错误处理和恢复
        case (.errorOccurred(let error), _):
            return .error(error)
            
        case (.recoveryAttempted, .error(let error)):
            return .recovering(from: error)
            
        case (.recoverySucceeded, .recovering):
            return .ready
            
        case (.recoveryFailed, .recovering):
            return .degraded(reason: "自动恢复失败")
            
        case (.degradeModeEntered(let reason), _):
            return .degraded(reason: reason)
            
        // 重置
        case (.reset, _):
            await resetRetryCounters()
            return .uninitialized
            
        default:
            logger.warning("Unhandled event: \(event) in state: \(state)")
            return state
        }
    }
    
    private func handleDataFetchError(_ error: HealthError, isInitial: Bool) async -> HealthState {
        let retries = await incrementRetryCount(for: error)
        
        if retries < self.maxRetries {
            logger.info("Data fetch failed, will retry (\(retries)/\(self.maxRetries))")
            return .recovering(from: error)
        } else {
            logger.warning("Data fetch failed after \(self.maxRetries) retries, entering degraded mode")
            return .degraded(reason: "数据获取多次失败")
        }
    }
    
    private func handleProcessingError(_ error: HealthError) async -> HealthState {
        let retries = await incrementRetryCount(for: error)
        
        if retries < self.maxRetries {
            logger.info("Data processing failed, will retry (\(retries)/\(self.maxRetries))")
            return .recovering(from: error)
        } else {
            logger.error("Data processing failed after \(self.maxRetries) retries")
            return .error(error)
        }
    }
    
    // MARK: - State Transitions
    
    private func transition(to newState: HealthState, via event: HealthEvent) async {
        let previousState = currentState
        currentState = newState
        
        // 记录状态历史
        stateHistory.append((state: newState, timestamp: Date()))
        
        // 限制历史记录大小
        if stateHistory.count > 100 {
            stateHistory.removeFirst(stateHistory.count - 100)
        }
        
        // 执行状态进入操作
        await onStateEnter(newState, from: previousState, via: event)
        
        // 发布状态变化事件
        await publishStateChangeEvent(from: previousState, to: newState, via: event)
    }
    
    private func onStateEnter(_ state: HealthState, from previousState: HealthState, via event: HealthEvent) async {
        switch state {
        case .recovering(let error):
            await startRecoveryProcess(for: error)
            
        case .degraded(let reason):
            logger.warning("Entered degraded mode: \(reason)")
            await resetRetryCounters()
            
        case .ready:
            await resetRetryCounters()
            logger.info("System is ready for operations")
            
        case .error(let error):
            logger.error("System entered error state: \(error)")
            
        default:
            break
        }
    }
    
    // MARK: - Recovery Mechanism
    
    private func startRecoveryProcess(for error: HealthError) async {
        logger.info("Starting recovery process for error: \(error)")
        
        // 启动恢复定时器
        scheduleRecoveryTimeout()
        
        // 根据错误类型执行不同的恢复策略
        let recoveryDelay: TimeInterval
        switch error {
        case .networkError:
            recoveryDelay = 5.0  // 网络错误：5秒后重试
        case .dataUnavailable:
            recoveryDelay = 10.0 // 数据不可用：10秒后重试
        case .processingError:
            recoveryDelay = 3.0  // 处理错误：3秒后重试
        default:
            recoveryDelay = 15.0 // 其他错误：15秒后重试
        }
        
        // 延迟后尝试恢复
        Task {
            try? await Task.sleep(nanoseconds: UInt64(recoveryDelay * 1_000_000_000))
            
            let success = await attemptRecovery(for: error)
            let recoveryEvent: HealthEvent = success ? .recoverySucceeded : .recoveryFailed
            
            let _ = await handle(recoveryEvent)
        }
    }
    
    private func attemptRecovery(for error: HealthError) async -> Bool {
        logger.info("Attempting recovery for error: \(error)")
        
        switch error {
        case .networkError:
            // 检查网络连接
            return await checkNetworkConnectivity()
            
        case .dataUnavailable:
            // 尝试重新获取数据
            return await retryDataFetch()
            
        case .processingError:
            // 清除缓存并重试
            return await retryDataProcessing()
            
        case .permissionDenied:
            // 权限错误通常需要用户干预
            return false
            
        default:
            // 通用恢复尝试
            return await performGenericRecovery()
        }
    }
    
    private func scheduleRecoveryTimeout() {
        // 取消现有定时器
        recoveryTimer?.invalidate()
        
        // 创建新的超时定时器
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            Task {
                guard let self = self else { return }
                await self.handle(.errorOccurred(.recoveryTimeout))
            }
        }
    }
    
    // MARK: - Validation
    
    private func isValidTransition(from currentState: HealthState, to newState: HealthState) -> Bool {
        // 获取当前状态允许的转换
        let allowedTransitions = getValidTransitions(for: currentState)
        
        // 检查新状态是否在允许列表中
        return allowedTransitions.contains { areStatesEqual($0, newState) }
    }
    
    private func getValidTransitions(for state: HealthState) -> Set<HealthState> {
        // 这里实现基于状态类型的匹配逻辑
        switch state {
        case .uninitialized:
            return [.initializing]
        case .initializing:
            return [.waitingForPermission, .error(.systemError(""))]
        case .waitingForPermission:
            return [.authorized, .permissionDenied, .error(.systemError(""))]
        case .permissionDenied:
            return [.waitingForPermission, .degraded(reason: "")]
        case .authorized:
            return [.fetchingInitialData, .ready, .error(.systemError(""))]
        case .fetchingInitialData:
            return [.ready, .error(.dataUnavailable), .degraded(reason: ""), .recovering(from: .dataUnavailable)]
        case .ready:
            return [.fetchingData, .processingData, .error(.systemError(""))]
        case .fetchingData:
            return [.ready, .processingData, .error(.dataUnavailable), .recovering(from: .networkError)]
        case .processingData:
            return [.ready, .error(.processingError("")), .recovering(from: .processingError(""))]
        case .error:
            return [.recovering(from: .systemError("")), .degraded(reason: "")]
        case .recovering:
            return [.ready, .degraded(reason: ""), .error(.recoveryTimeout)]
        case .degraded:
            return [.ready, .error(.systemError(""))]
        }
    }
    
    private func areStatesEqual(_ state1: HealthState, _ state2: HealthState) -> Bool {
        switch (state1, state2) {
        case (.uninitialized, .uninitialized),
             (.initializing, .initializing),
             (.waitingForPermission, .waitingForPermission),
             (.permissionDenied, .permissionDenied),
             (.authorized, .authorized),
             (.fetchingInitialData, .fetchingInitialData),
             (.ready, .ready),
             (.fetchingData, .fetchingData),
             (.processingData, .processingData):
            return true
        case (.error, .error),
             (.recovering, .recovering),
             (.degraded, .degraded):
            return true  // 对于错误、恢复和降级状态，我们认为类型匹配即可
        default:
            return false
        }
    }
    
    // MARK: - Event Publishing
    
    private func publishStateChangeEvent(from previousState: HealthState, to newState: HealthState, via event: HealthEvent) async {
        await eventBus.publish(DefaultEvent(
            eventType: "HealthStateMachineStateChanged",
            source: "HealthStateMachine",
            metadata: [
                "previousState": String(describing: previousState),
                "newState": String(describing: newState),
                "triggerEvent": String(describing: event),
                "timestamp": String(Date().timeIntervalSince1970)
            ]
        ))
    }
    
    // MARK: - Retry Management
    
    private func incrementRetryCount(for error: HealthError) async -> Int {
        let currentCount = retryCount[error] ?? 0
        let newCount = currentCount + 1
        retryCount[error] = newCount
        return newCount
    }
    
    private func resetRetryCounters() async {
        retryCount.removeAll()
    }
    
    // MARK: - Recovery Operations
    
    private func checkNetworkConnectivity() async -> Bool {
        // 实现网络连接检查
        // 这里可以ping一个可靠的服务器或检查网络接口状态
        logger.info("Checking network connectivity")
        
        // 模拟网络检查
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 实际实现应该检查真实的网络状态
        return true // 假设网络恢复
    }
    
    private func retryDataFetch() async -> Bool {
        logger.info("Retrying data fetch")
        
        // 这里应该触发实际的数据重新获取
        // 可以通过发送消息给HealthActor来实现
        
        // 模拟数据获取尝试
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        return true // 假设数据获取成功
    }
    
    private func retryDataProcessing() async -> Bool {
        logger.info("Retrying data processing")
        
        // 清除可能的缓存问题
        // 重试数据处理逻辑
        
        // 模拟处理重试
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
        
        return true // 假设处理成功
    }
    
    private func performGenericRecovery() async -> Bool {
        logger.info("Performing generic recovery")
        
        // 通用恢复策略：
        // 1. 清除临时状态
        // 2. 重置连接
        // 3. 重新初始化必要组件
        
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
        
        return false // 通用恢复通常成功率较低
    }
    
    // MARK: - Diagnostics
    
    /**
     * 获取状态机诊断信息
     */
    func getDiagnostics() async -> HealthStateMachineDiagnostics {
        let now = Date()
        let recentHistory = stateHistory.suffix(10)
        
        let timeInCurrentState = stateHistory.last?.timestamp.distance(to: now) ?? 0
        
        return HealthStateMachineDiagnostics(
            currentState: currentState,
            timeInCurrentState: timeInCurrentState,
            totalTransitions: stateHistory.count,
            recentHistory: Array(recentHistory),
            retryCounters: retryCount,
            isOperational: currentState.isOperational
        )
    }
}

// MARK: - Supporting Types

/**
 * 健康操作枚举
 */
enum HealthOperation {
    case fetchData
    case processData
    case requestPermission
    case recover
}

/**
 * 健康状态机诊断信息
 */
struct HealthStateMachineDiagnostics {
    let currentState: HealthStateMachine.HealthState
    let timeInCurrentState: TimeInterval
    let totalTransitions: Int
    let recentHistory: [(state: HealthStateMachine.HealthState, timestamp: Date)]
    let retryCounters: [HealthStateMachine.HealthError: Int]
    let isOperational: Bool
    
    var healthScore: Double {
        // 基于各种因素计算健康分数
        var score = 1.0
        
        // 状态因子
        switch currentState {
        case .ready: score *= 1.0
        case .fetchingData, .processingData: score *= 0.9
        case .degraded: score *= 0.6
        case .recovering: score *= 0.4
        case .error: score *= 0.2
        default: score *= 0.3
        }
        
        // 重试次数因子
        let totalRetries = retryCounters.values.reduce(0, +)
        score *= max(0.1, 1.0 - Double(totalRetries) * 0.1)
        
        // 稳定性因子（在当前状态停留时间）
        if timeInCurrentState > 60 && currentState.isOperational {
            score *= 1.1 // 稳定状态加分
        } else if timeInCurrentState > 300 && !currentState.isOperational {
            score *= 0.8 // 长时间非操作状态扣分
        }
        
        return max(0.0, min(1.0, score))
    }
}