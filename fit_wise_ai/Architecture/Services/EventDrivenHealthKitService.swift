//
//  EventDrivenHealthKitService.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import HealthKit
import OSLog
import Combine

// MARK: - 消息类型定义
struct RequestHealthPermissionMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "RequestHealthPermission"
    let permissions: [HKObjectType]
}

struct FetchTodayHealthDataMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "FetchTodayHealthData"
}

struct FetchHistoricalHealthDataMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "FetchHistoricalHealthData"
    let dateRange: DateInterval
}

struct FetchSpecificMetricMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "FetchSpecificMetric"
    let metricType: String
    let dateRange: DateInterval
}

struct SetHealthGoalMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "SetHealthGoal"
    let goalType: String
    let targetValue: Double
    let timeFrame: String
}

struct CheckHealthGoalMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType = "CheckHealthGoal"
    let goalType: String
}

// MARK: - 响应类型定义
struct HistoricalHealthDataResponse: Sendable {
    let historicalData: [HealthDataSnapshot]
    let dateRange: DateInterval
    let dataCompleteness: Double
}

struct HealthGoalResponse: Sendable {
    let goalSet: Bool
    let goalType: String
    let targetValue: Double
    let currentValue: Double?
}

struct HealthGoalCheckResponse: Sendable {
    let goalAchieved: Bool
    let goalType: String
    let targetValue: Double
    let currentValue: Double
    let progress: Double
}

/**
 * 事件驱动的HealthKit服务
 * 
 * 重构后的HealthKit服务，完全基于事件驱动架构：
 * - 所有操作都通过事件记录和追踪
 * - 与HealthActor协同工作
 * - 支持事件重放和状态恢复
 * - 提供详细的审计跟踪
 */
@MainActor
class EventDrivenHealthKitService: ObservableObject {
    
    // MARK: - Properties
    
    /// HealthKit存储实例
    private let healthStore = HKHealthStore()
    /// 事件总线引用
    private let eventBus = EventBus.shared
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "EventDrivenHealthKitService")
    /// HealthActor引用
    private var healthActor: HealthActor?
    /// 当前状态
    @Published private(set) var currentState: HealthKitServiceState = .uninitialized
    /// 权限状态
    @Published private(set) var permissionStatus: [String: HKAuthorizationStatus] = [:]
    /// 最新健康数据
    @Published private(set) var latestHealthData: HealthDataSnapshot?
    /// 错误状态
    @Published private(set) var lastError: Error?
    /// 取消订阅集合
    private var cancellables = Set<AnyCancellable>()
    /// 数据观察器
    private var healthObservers: [HKObserverQuery] = []
    
    // MARK: - 支持的健康数据类型
    
    private let supportedHealthTypes: [HKQuantityTypeIdentifier: String] = [
        .stepCount: "步数",
        .distanceWalkingRunning: "步行+跑步距离",
        .activeEnergyBurned: "活动消耗",
        .heartRate: "心率",
        .restingHeartRate: "静息心率",
        .bodyMass: "体重",
        .height: "身高"
    ]
    
    // MARK: - Initialization
    
    init() {
        logger.info("EventDrivenHealthKitService initializing")
        setupEventSubscriptions()
        initializeService()
    }
    
    deinit {
        Task {
            await cleanupObservers()
        }
        logger.info("EventDrivenHealthKitService deinitialized")
    }
    
    // MARK: - Service Initialization
    
    private func initializeService() {
        Task {
            await transitionTo(.initializing)
            
            // 检查HealthKit可用性
            guard HKHealthStore.isHealthDataAvailable() else {
                logger.error("HealthKit is not available on this device")
                await transitionTo(.unavailable)
                return
            }
            
            // 注册HealthActor
            healthActor = HealthActor()
            if let actor = healthActor {
                await ActorSystem.shared.register(actor)
            }
            
            await transitionTo(.ready)
            logger.info("EventDrivenHealthKitService initialized successfully")
        }
    }
    
    // MARK: - Event Subscriptions
    
    private func setupEventSubscriptions() {
        // 订阅健康权限事件
        eventBus.subscribe(to: HealthPermissionRequestedEvent.self) { [weak self] event in
            await self?.handlePermissionRequestedEvent(event)
            return .success
        }
        
        // 订阅健康数据获取事件
        eventBus.subscribe(to: HealthDataFetchStartedEvent.self) { [weak self] event in
            await self?.handleDataFetchStartedEvent(event)
            return .success
        }
        
        // 订阅健康数据更新事件
        eventBus.subscribe(to: HealthDataUpdatedEvent.self) { [weak self] event in
            await self?.handleDataUpdatedEvent(event)
            return .success
        }
        
        logger.info("Event subscriptions set up")
    }
    
    // MARK: - State Management
    
    private func transitionTo(_ newState: HealthKitServiceState) async {
        let previousState = currentState
        currentState = newState
        
        logger.info("State transition: \(previousState) -> \(newState)")
        
        // 发布状态变化事件
        await eventBus.publish(DefaultEvent(
            eventType: "HealthKitServiceStateChanged",
            source: "EventDrivenHealthKitService",
            metadata: [
                "previousState": String(describing: previousState),
                "newState": String(describing: newState)
            ]
        ))
    }
    
    // MARK: - Public Interface
    
    /**
     * 请求HealthKit权限
     */
    func requestAuthorization() async -> Bool {
        guard currentState == .ready else {
            logger.warning("Service not ready for authorization request")
            return false
        }
        
        await transitionTo(.requestingPermissions)
        
        // 准备权限请求
        let typesToRead = Set(supportedHealthTypes.keys.compactMap { 
            HKQuantityType.quantityType(forIdentifier: $0) 
        }) as Set<HKObjectType>
        
        let workoutType = HKObjectType.workoutType()
        let allTypes = typesToRead.union([workoutType])
        
        do {
            // 通过HealthActor请求权限
            if let actor = healthActor {
                let message = RequestHealthPermissionMessage(permissions: Array(allTypes))
                let response: HealthPermissionResponse = try await actor.ask(message)
                
                // 更新权限状态
                updatePermissionStatus(from: response.authorizationStatus)
                
                if response.isAuthorized {
                    await transitionTo(.authorized)
                    setupDataObservers()
                    return true
                } else {
                    await transitionTo(.permissionDenied)
                    return false
                }
            } else {
                throw HealthKitServiceError.actorNotAvailable
            }
            
        } catch {
            logger.error("Authorization request failed: \(error)")
            lastError = error
            await transitionTo(.error(error))
            return false
        }
    }
    
    /**
     * 获取今日健康数据
     */
    func fetchTodayHealthData() async -> HealthDataSnapshot? {
        guard currentState == .authorized else {
            logger.warning("Not authorized to fetch health data")
            return nil
        }
        
        await transitionTo(.fetchingData)
        
        do {
            if let actor = healthActor {
                let message = FetchTodayHealthDataMessage()
                let response: HealthDataResponse = try await actor.ask(message)
                
                latestHealthData = response.healthData
                await transitionTo(.ready)
                
                return response.healthData
            } else {
                throw HealthKitServiceError.actorNotAvailable
            }
            
        } catch {
            logger.error("Failed to fetch today's health data: \(error)")
            lastError = error
            await transitionTo(.error(error))
            return nil
        }
    }
    
    /**
     * 获取历史健康数据
     */
    func fetchHistoricalHealthData(dateRange: DateInterval) async -> [HealthDataSnapshot] {
        guard currentState == .authorized else {
            logger.warning("Not authorized to fetch health data")
            return []
        }
        
        await transitionTo(.fetchingData)
        
        do {
            if let actor = healthActor {
                let message = FetchHistoricalHealthDataMessage(dateRange: dateRange)
                let response: HistoricalHealthDataResponse = try await actor.ask(message)
                
                await transitionTo(.ready)
                return response.historicalData
            } else {
                throw HealthKitServiceError.actorNotAvailable
            }
            
        } catch {
            logger.error("Failed to fetch historical health data: \(error)")
            lastError = error
            await transitionTo(.error(error))
            return []
        }
    }
    
    /**
     * 获取特定指标数据
     */
    func fetchSpecificMetric(_ metricType: String, dateRange: DateInterval) async -> [String: Any]? {
        guard currentState == .authorized else {
            logger.warning("Not authorized to fetch health data")
            return nil
        }
        
        do {
            if let actor = healthActor {
                let message = FetchSpecificMetricMessage(
                    metricType: metricType,
                    dateRange: dateRange
                )
                let response: [String: Any] = try await actor.ask(message)
                return response
            } else {
                throw HealthKitServiceError.actorNotAvailable
            }
        } catch {
            logger.error("Failed to fetch \(metricType) data: \(error)")
            return nil
        }
    }
    
    /**
     * 设置健康目标
     */
    func setHealthGoal(type: String, targetValue: Double, timeFrame: String) async -> Bool {
        do {
            if let actor = healthActor {
                let message = SetHealthGoalMessage(
                    goalType: type,
                    targetValue: targetValue,
                    timeFrame: timeFrame
                )
                let response: HealthGoalResponse = try await actor.ask(message)
                return response.goalSet
            }
        } catch {
            logger.error("Failed to set health goal: \(error)")
        }
        return false
    }
    
    /**
     * 检查健康目标达成情况
     */
    func checkHealthGoal(_ goalType: String) async -> Bool {
        do {
            if let actor = healthActor {
                let message = CheckHealthGoalMessage(goalType: goalType)
                let response: HealthGoalCheckResponse = try await actor.ask(message)
                return response.goalAchieved
            }
        } catch {
            logger.error("Failed to check health goal: \(error)")
        }
        return false
    }
    
    // MARK: - Real-time Data Monitoring
    
    /**
     * 设置健康数据观察器
     */
    private func setupDataObservers() {
        guard currentState == .authorized else { return }
        
        // 清理现有观察器
        cleanupObservers()
        
        // 为每种数据类型设置观察器
        for (identifier, _) in supportedHealthTypes {
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            
            let observer = HKObserverQuery(sampleType: quantityType, predicate: nil) { [weak self] _, _, error in
                Task { @MainActor in
                    if let error = error {
                        self?.logger.error("Observer query error for \(identifier.rawValue): \(error)")
                        return
                    }
                    
                    await self?.handleHealthDataChange(for: identifier)
                }
            }
            
            healthStore.execute(observer)
            healthObservers.append(observer)
        }
        
        logger.info("Health data observers set up for \(self.healthObservers.count) data types")
    }
    
    /**
     * 处理健康数据变化
     */
    private func handleHealthDataChange(for identifier: HKQuantityTypeIdentifier) async {
        logger.info("Health data change detected for: \(identifier.rawValue)")
        
        // 获取更新的数据
        if let updatedData = await fetchTodayHealthData() {
            // 比较数据变化
            let changedFields = identifyChangedFields(
                previous: latestHealthData,
                current: updatedData
            )
            
            if !changedFields.isEmpty {
                // 发布健康数据更新事件
                await eventBus.publish(HealthDataUpdatedEvent(
                    previousData: latestHealthData,
                    currentData: updatedData,
                    changedFields: changedFields,
                    source: "EventDrivenHealthKitService"
                ))
            }
        }
    }
    
    /**
     * 清理观察器
     */
    private func cleanupObservers() {
        for observer in healthObservers {
            healthStore.stop(observer)
        }
        healthObservers.removeAll()
        logger.info("Health data observers cleaned up")
    }
    
    // MARK: - Event Handlers
    
    private func handlePermissionRequestedEvent(_ event: HealthPermissionRequestedEvent) async {
        logger.info("Handling permission requested event for \(event.requestedPermissions.count) permissions")
        // 这里可以添加额外的权限请求前处理逻辑
    }
    
    private func handleDataFetchStartedEvent(_ event: HealthDataFetchStartedEvent) async {
        logger.info("Data fetch started for types: \(event.dataTypes)")
        // 可以在这里更新UI状态或显示加载指示器
    }
    
    private func handleDataUpdatedEvent(_ event: HealthDataUpdatedEvent) async {
        // 更新本地状态
        latestHealthData = event.currentData
        logger.info("Health data updated with changes in: \(event.changedFields)")
    }
    
    // MARK: - Helper Methods
    
    private func updatePermissionStatus(from authStatus: [String: String]) {
        for (identifier, statusString) in authStatus {
            let status: HKAuthorizationStatus
            switch statusString {
            case "authorized": status = .sharingAuthorized
            case "denied": status = .sharingDenied
            default: status = .notDetermined
            }
            permissionStatus[identifier] = status
        }
    }
    
    private func identifyChangedFields(
        previous: HealthDataSnapshot?,
        current: HealthDataSnapshot
    ) -> [String] {
        guard let previous = previous else {
            return ["steps", "heartRate", "activeEnergyBurned", "workoutTime", "distanceWalkingRunning"]
        }
        
        return current.diff(from: previous)
    }
    
    // MARK: - Status and Diagnostics
    
    /**
     * 获取服务状态报告
     */
    func getStatusReport() -> HealthKitServiceStatusReport {
        return HealthKitServiceStatusReport(
            currentState: currentState,
            isHealthKitAvailable: HKHealthStore.isHealthDataAvailable(),
            permissionStatus: permissionStatus,
            supportedDataTypes: Array(supportedHealthTypes.keys.map { $0.rawValue }),
            activeObservers: healthObservers.count,
            latestDataTimestamp: latestHealthData?.date,
            lastError: lastError
        )
    }
    
    /**
     * 执行健康服务诊断
     */
    func performDiagnostics() async -> String {
        var report = "📱 EventDriven HealthKit Service 诊断报告\n\n"
        
        // 基本状态
        report += "🔍 基本状态\n"
        report += "   服务状态: \(currentState)\n"
        report += "   HealthKit可用性: \(HKHealthStore.isHealthDataAvailable() ? "可用" : "不可用")\n"
        report += "   Actor状态: \(healthActor != nil ? "已连接" : "未连接")\n\n"
        
        // 权限状态
        report += "🔐 权限状态\n"
        for (identifier, status) in permissionStatus {
            let statusText = switch status {
            case .notDetermined: "未决定"
            case .sharingDenied: "已拒绝"
            case .sharingAuthorized: "已授权"
            @unknown default: "未知"
            }
            report += "   \(supportedHealthTypes[HKQuantityTypeIdentifier(rawValue: identifier)] ?? identifier): \(statusText)\n"
        }
        report += "\n"
        
        // 数据状态
        report += "📊 数据状态\n"
        if let data = latestHealthData {
            report += "   最新数据时间: \(DateFormatter.localizedString(from: data.date, dateStyle: .medium, timeStyle: .short))\n"
            report += "   步数: \(data.steps)\n"
            report += "   心率: \(data.heartRate.map { String(format: "%.0f", $0) } ?? "无")\n"
            report += "   活动消耗: \(String(format: "%.0f", data.activeEnergyBurned))卡\n"
            report += "   运动时间: \(String(format: "%.0f", data.workoutTime/60))分钟\n"
            report += "   距离: \(String(format: "%.1f", data.distanceWalkingRunning/1000))公里\n"
        } else {
            report += "   无可用数据\n"
        }
        report += "\n"
        
        // 监听器状态
        report += "👁 数据监听器\n"
        report += "   活跃观察器: \(healthObservers.count)个\n"
        report += "   监听数据类型: \(supportedHealthTypes.count)种\n\n"
        
        // 错误状态
        if let error = lastError {
            report += "❌ 最后错误\n"
            report += "   错误信息: \(error.localizedDescription)\n\n"
        }
        
        // 性能统计
        if let actor = healthActor {
            let stats = await actor.getStatistics()
            report += "⚡ Actor性能统计\n"
            report += "   处理消息数: \(stats.messagesProcessed)\n"
            report += "   队列中消息: \(stats.messagesQueued)\n"
            report += "   平均处理时间: \(String(format: "%.2f", stats.averageProcessingTime * 1000))ms\n"
            report += "   错误数量: \(stats.errorCount)\n"
        }
        
        return report
    }
}

// MARK: - Supporting Types

/**
 * HealthKit服务状态枚举
 */
enum HealthKitServiceState: CustomStringConvertible, Equatable {
    case uninitialized          // 未初始化
    case initializing           // 初始化中
    case ready                  // 就绪（未授权）
    case requestingPermissions  // 请求权限中
    case authorized            // 已授权
    case permissionDenied      // 权限被拒绝
    case fetchingData          // 获取数据中
    case unavailable           // 不可用
    case error(Error)          // 错误状态
    
    var description: String {
        switch self {
        case .uninitialized: return "未初始化"
        case .initializing: return "初始化中"
        case .ready: return "就绪"
        case .requestingPermissions: return "请求权限中"
        case .authorized: return "已授权"
        case .permissionDenied: return "权限被拒绝"
        case .fetchingData: return "获取数据中"
        case .unavailable: return "不可用"
        case .error(let error): return "错误: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: HealthKitServiceState, rhs: HealthKitServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized), (.initializing, .initializing),
             (.ready, .ready), (.requestingPermissions, .requestingPermissions),
             (.authorized, .authorized), (.permissionDenied, .permissionDenied),
             (.fetchingData, .fetchingData), (.unavailable, .unavailable):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/**
 * HealthKit服务错误类型
 */
enum HealthKitServiceError: Error, LocalizedError {
    case actorNotAvailable
    case serviceNotReady
    case permissionDenied
    case dataFetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .actorNotAvailable:
            return "Health Actor not available"
        case .serviceNotReady:
            return "HealthKit service is not ready"
        case .permissionDenied:
            return "HealthKit permission denied"
        case .dataFetchFailed(let error):
            return "Data fetch failed: \(error.localizedDescription)"
        }
    }
}

/**
 * HealthKit服务状态报告
 */
struct HealthKitServiceStatusReport {
    let currentState: HealthKitServiceState
    let isHealthKitAvailable: Bool
    let permissionStatus: [String: HKAuthorizationStatus]
    let supportedDataTypes: [String]
    let activeObservers: Int
    let latestDataTimestamp: Date?
    let lastError: Error?
    
    var isHealthy: Bool {
        switch currentState {
        case .authorized, .ready:
            return true
        default:
            return false
        }
    }
    
    var hasValidData: Bool {
        guard let timestamp = latestDataTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < 86400 // 24小时内的数据
    }
}