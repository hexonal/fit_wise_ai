//
//  BaseEvent.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation

/**
 * 基础事件协议
 * 
 * Event Sourcing架构的核心接口，定义了所有事件必须遵循的基本规范。
 * 每个事件都代表系统中发生的一个不可变的业务事实。
 */
protocol BaseEvent: Codable, Identifiable, Sendable {
    /// 事件唯一标识符
    var id: UUID { get }
    /// 事件类型标识（用于事件路由和处理）
    var eventType: String { get }
    /// 事件发生时间戳
    var timestamp: Date { get }
    /// 事件版本（用于向后兼容）
    var version: Int { get }
    /// 事件来源（哪个Actor产生的）
    var source: String { get }
    /// 事件元数据（可选，用于存储额外信息）
    var metadata: [String: String]? { get }
}

/**
 * 默认事件基类实现
 * 
 * 提供BaseEvent协议的默认实现，减少重复代码
 */
struct DefaultEvent: BaseEvent {
    let id: UUID
    let eventType: String
    let timestamp: Date
    let version: Int
    let source: String
    let metadata: [String: String]?
    
    init(
        eventType: String,
        source: String,
        version: Int = 1,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.eventType = eventType
        self.timestamp = Date()
        self.version = version
        self.source = source
        self.metadata = metadata
    }
}

/**
 * 事件聚合器
 * 
 * 将多个相关事件组合成一个聚合事件，用于批处理场景
 */
struct AggregateEvent: BaseEvent {
    let id: UUID
    let eventType: String = "AggregateEvent"
    let timestamp: Date
    let version: Int
    let source: String
    let metadata: [String: String]?
    
    /// 聚合名称
    let aggregateName: String
    /// 事件数量（简化版）
    let eventCount: Int
    
    init(
        aggregateName: String,
        events: [any BaseEvent],
        source: String,
        version: Int = 1,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.version = version
        self.source = source
        self.metadata = metadata
        self.eventCount = events.count
        self.aggregateName = aggregateName
    }
}

/**
 * 事件处理结果
 * 
 * 封装事件处理的结果状态
 */
enum EventHandlingResult {
    case success
    case failure(Error)
    case ignored(reason: String)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure, .ignored:
            return false
        }
    }
}