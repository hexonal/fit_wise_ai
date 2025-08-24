//
//  HealthEvents.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import HealthKit

/**
 * 健康相关事件定义
 * 
 * 定义所有与健康数据相关的事件类型，遵循Event Sourcing模式
 */

// MARK: - HealthKit权限事件

/// HealthKit权限请求事件
struct HealthPermissionRequestedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthPermissionRequested"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 请求的权限类型列表
    let requestedPermissions: [String]
    
    init(
        requestedPermissions: [HKObjectType],
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.requestedPermissions = requestedPermissions.map { $0.identifier }
        self.source = source
        self.metadata = metadata
    }
}

/// HealthKit权限授权事件
struct HealthPermissionGrantedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthPermissionGranted"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 授权状态映射 (权限ID -> 状态)
    let authorizationStatus: [String: String]
    
    init(
        authorizationStatus: [String: String],
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.authorizationStatus = authorizationStatus
        self.source = source
        self.metadata = metadata
    }
}

/// HealthKit权限拒绝事件
struct HealthPermissionDeniedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthPermissionDenied"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 被拒绝的权限列表
    let deniedPermissions: [String]
    /// 拒绝原因
    let reason: String?
    
    init(
        deniedPermissions: [String],
        reason: String? = nil,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.deniedPermissions = deniedPermissions
        self.reason = reason
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - 健康数据获取事件

/// 健康数据获取开始事件
struct HealthDataFetchStartedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthDataFetchStarted"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 获取数据的类型
    let dataTypes: [String]
    /// 查询的日期范围
    let dateRange: DateInterval
    
    init(
        dataTypes: [String],
        dateRange: DateInterval,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.dataTypes = dataTypes
        self.dateRange = dateRange
        self.source = source
        self.metadata = metadata
    }
}

/// 健康数据获取完成事件
struct HealthDataFetchCompletedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthDataFetchCompleted"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 获取到的健康数据
    let healthData: HealthDataSnapshot
    /// 获取耗时（毫秒）
    let fetchDuration: TimeInterval
    
    init(
        healthData: HealthDataSnapshot,
        fetchDuration: TimeInterval,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.healthData = healthData
        self.fetchDuration = fetchDuration
        self.source = source
        self.metadata = metadata
    }
}

/// 健康数据获取失败事件
struct HealthDataFetchFailedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthDataFetchFailed"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 错误信息
    let error: String
    /// 失败的数据类型
    let failedDataTypes: [String]
    
    init(
        error: Error,
        failedDataTypes: [String],
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.error = error.localizedDescription
        self.failedDataTypes = failedDataTypes
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - 健康数据更新事件

/// 健康数据更新事件
struct HealthDataUpdatedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthDataUpdated"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 更新前的数据快照
    let previousData: HealthDataSnapshot?
    /// 更新后的数据快照
    let currentData: HealthDataSnapshot
    /// 变化的字段列表
    let changedFields: [String]
    
    init(
        previousData: HealthDataSnapshot?,
        currentData: HealthDataSnapshot,
        changedFields: [String],
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.previousData = previousData
        self.currentData = currentData
        self.changedFields = changedFields
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - 健康数据快照模型

/// 健康数据快照
/// 
/// 不可变的健康数据状态，用于事件存储
struct HealthDataSnapshot: Codable, Sendable {
    let date: Date
    let steps: Int
    let heartRate: Double?
    let activeEnergyBurned: Double
    let workoutTime: TimeInterval
    let distanceWalkingRunning: Double
    
    /// 从HealthData转换
    init(from healthData: HealthData) {
        self.date = healthData.date
        self.steps = healthData.steps
        self.heartRate = healthData.heartRate
        self.activeEnergyBurned = healthData.activeEnergyBurned
        self.workoutTime = healthData.workoutTime
        self.distanceWalkingRunning = healthData.distanceWalkingRunning
    }
    
    /// 转换为HealthData
    func toHealthData() -> HealthData {
        return HealthData(
            date: date,
            steps: steps,
            heartRate: heartRate,
            activeEnergyBurned: activeEnergyBurned,
            workoutTime: workoutTime,
            distanceWalkingRunning: distanceWalkingRunning
        )
    }
    
    /// 比较两个快照的差异
    func diff(from other: HealthDataSnapshot?) -> [String] {
        guard let other = other else {
            return ["steps", "heartRate", "activeEnergyBurned", "workoutTime", "distanceWalkingRunning"]
        }
        
        var changes: [String] = []
        
        if steps != other.steps { changes.append("steps") }
        if heartRate != other.heartRate { changes.append("heartRate") }
        if activeEnergyBurned != other.activeEnergyBurned { changes.append("activeEnergyBurned") }
        if workoutTime != other.workoutTime { changes.append("workoutTime") }
        if distanceWalkingRunning != other.distanceWalkingRunning { changes.append("distanceWalkingRunning") }
        
        return changes
    }
}

// MARK: - 健康目标事件

/// 健康目标设定事件
struct HealthGoalSetEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthGoalSet"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 目标类型（步数、卡路里等）
    let goalType: String
    /// 目标值
    let targetValue: Double
    /// 目标时间范围
    let timeFrame: String // daily, weekly, monthly
    
    init(
        goalType: String,
        targetValue: Double,
        timeFrame: String,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.goalType = goalType
        self.targetValue = targetValue
        self.timeFrame = timeFrame
        self.source = source
        self.metadata = metadata
    }
}

/// 健康目标达成事件
struct HealthGoalAchievedEvent: BaseEvent {
    let id = UUID()
    let eventType = "HealthGoalAchieved"
    let timestamp = Date()
    let version = 1
    let source: String
    let metadata: [String: String]?
    
    /// 达成的目标类型
    let goalType: String
    /// 目标值
    let targetValue: Double
    /// 实际达成值
    let actualValue: Double
    /// 达成时间
    let achievedAt: Date
    
    init(
        goalType: String,
        targetValue: Double,
        actualValue: Double,
        achievedAt: Date,
        source: String,
        metadata: [String: String]? = nil
    ) {
        self.goalType = goalType
        self.targetValue = targetValue
        self.actualValue = actualValue
        self.achievedAt = achievedAt
        self.source = source
        self.metadata = metadata
    }
}