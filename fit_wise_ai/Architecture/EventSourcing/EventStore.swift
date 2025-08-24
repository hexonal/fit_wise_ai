//
//  EventStore.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import OSLog
import Combine

/**
 * Event Store - 事件存储核心类
 * 
 * Event Sourcing架构的核心组件，负责：
 * - 存储和检索事件
 * - 事件版本控制
 * - 事件流管理
 * - 快照管理
 */
actor EventStore {
    
    // MARK: - Properties
    
    /// 内存中的事件存储（生产环境应使用持久化存储）
    private var events: [any BaseEvent] = []
    /// 事件索引，用于快速查找
    private var eventIndex: [String: [Int]] = [:] // eventType -> [eventIndex]
    /// 快照存储
    private var snapshots: [String: any Codable] = [:] // streamId -> snapshot
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "EventStore")
    /// 事件发布器（用于通知订阅者）
    private let eventPublisher = PassthroughSubject<any BaseEvent, Never>()
    
    // MARK: - 单例模式
    
    static let shared = EventStore()
    
    private init() {
        logger.info("EventStore initialized")
    }
    
    // MARK: - 事件存储
    
    /**
     * 存储单个事件
     */
    func append(_ event: any BaseEvent) async {
        events.append(event)
        
        // 更新索引
        let eventType = event.eventType
        if eventIndex[eventType] == nil {
            eventIndex[eventType] = []
        }
        eventIndex[eventType]?.append(events.count - 1)
        
        logger.info("Event appended: \(eventType) from \(event.source)")
        
        // 发布事件通知
        eventPublisher.send(event)
    }
    
    /**
     * 批量存储事件
     */
    func appendBatch(_ events: [any BaseEvent]) async {
        for event in events {
            await append(event)
        }
        
        logger.info("Batch of \(events.count) events appended")
    }
    
    /**
     * 存储聚合事件
     */
    func appendAggregate(_ aggregateEvent: AggregateEvent) async {
        // 先存储子事件
        // 简化版本中不支持子事件
        // for event in aggregateEvent.events {
        //     await append(event)
        // }
        
        // 再存储聚合事件本身
        await append(aggregateEvent)
        
        logger.info("Aggregate event appended: \(aggregateEvent.aggregateName) with \(aggregateEvent.eventCount) sub-events")
    }
    
    // MARK: - 事件检索
    
    /**
     * 获取所有事件
     */
    func getAllEvents() -> [any BaseEvent] {
        return events
    }
    
    /**
     * 根据事件类型获取事件
     */
    func getEventsByType<T: BaseEvent>(_ type: T.Type) -> [T] {
        let eventType = String(describing: type)
        guard let indices = eventIndex[eventType] else { return [] }
        
        return indices.compactMap { index in
            guard index < events.count else { return nil }
            return events[index] as? T
        }
    }
    
    /**
     * 根据来源获取事件
     */
    func getEventsBySource(_ source: String) -> [any BaseEvent] {
        return events.filter { $0.source == source }
    }
    
    /**
     * 根据时间范围获取事件
     */
    func getEventsByTimeRange(_ dateRange: DateInterval) -> [any BaseEvent] {
        return events.filter { dateRange.contains($0.timestamp) }
    }
    
    /**
     * 获取最新的N个事件
     */
    func getLatestEvents(count: Int) -> [any BaseEvent] {
        guard count > 0 else { return [] }
        let startIndex = max(0, events.count - count)
        return Array(events[startIndex...])
    }
    
    /**
     * 根据事件ID获取事件
     */
    func getEventById(_ id: UUID) -> (any BaseEvent)? {
        return events.first { $0.id == id }
    }
    
    // MARK: - 事件流查询
    
    /**
     * 创建事件流
     */
    func getEventStream(
        fromTimestamp: Date? = nil,
        toTimestamp: Date? = nil,
        eventTypes: [String]? = nil,
        sources: [String]? = nil
    ) -> AsyncStream<any BaseEvent> {
        
        return AsyncStream { continuation in
            Task {
                let filteredEvents = events.filter { event in
                    // 时间过滤
                    if let from = fromTimestamp, event.timestamp < from { return false }
                    if let to = toTimestamp, event.timestamp > to { return false }
                    
                    // 事件类型过滤
                    if let types = eventTypes, !types.contains(event.eventType) { return false }
                    
                    // 来源过滤
                    if let sources = sources, !sources.contains(event.source) { return false }
                    
                    return true
                }
                
                for event in filteredEvents {
                    continuation.yield(event)
                }
                
                continuation.finish()
            }
        }
    }
    
    // MARK: - 快照管理
    
    /**
     * 保存快照
     */
    func saveSnapshot<T: Codable>(_ snapshot: T, forStream streamId: String) async {
        snapshots[streamId] = snapshot
        logger.info("Snapshot saved for stream: \(streamId)")
    }
    
    /**
     * 获取快照
     */
    func getSnapshot<T: Codable>(forStream streamId: String, as type: T.Type) -> T? {
        return snapshots[streamId] as? T
    }
    
    // MARK: - 事件投影
    
    /**
     * 从事件重建状态（事件投影）
     */
    func projectState<T>(
        initialState: T,
        eventTypes: [String],
        projector: @escaping (T, any BaseEvent) -> T
    ) -> T {
        var state = initialState
        
        for event in events {
            if eventTypes.contains(event.eventType) {
                state = projector(state, event)
            }
        }
        
        return state
    }
    
    /**
     * 异步事件投影
     */
    func projectStateAsync<T>(
        initialState: T,
        eventTypes: [String],
        projector: @escaping (T, any BaseEvent) async -> T
    ) async -> T {
        var state = initialState
        
        for event in events {
            if eventTypes.contains(event.eventType) {
                state = await projector(state, event)
            }
        }
        
        return state
    }
    
    // MARK: - 事件统计
    
    /**
     * 获取事件统计信息
     */
    func getEventStatistics() -> EventStatistics {
        var typeCount: [String: Int] = [:]
        var sourceCount: [String: Int] = [:]
        
        for event in events {
            typeCount[event.eventType, default: 0] += 1
            sourceCount[event.source, default: 0] += 1
        }
        
        return EventStatistics(
            totalEvents: events.count,
            eventTypeCount: typeCount,
            sourceCount: sourceCount,
            oldestEvent: events.first?.timestamp,
            newestEvent: events.last?.timestamp
        )
    }
    
    // MARK: - 事件订阅
    
    /**
     * 获取事件发布器，用于订阅新事件
     */
    nonisolated func getEventPublisher() -> AnyPublisher<any BaseEvent, Never> {
        return eventPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - 清理和维护
    
    /**
     * 清理旧事件（根据时间阈值）
     */
    func cleanupOldEvents(olderThan threshold: Date) async -> Int {
        let initialCount = events.count
        
        events.removeAll { $0.timestamp < threshold }
        
        // 重建索引
        eventIndex.removeAll()
        for (index, event) in events.enumerated() {
            let eventType = event.eventType
            if eventIndex[eventType] == nil {
                eventIndex[eventType] = []
            }
            eventIndex[eventType]?.append(index)
        }
        
        let removedCount = initialCount - events.count
        logger.info("Cleaned up \(removedCount) old events")
        
        return removedCount
    }
    
    /**
     * 获取存储大小估计（字节）
     */
    func getStorageSize() -> Int {
        // 简单估算，实际实现应该更精确
        return events.count * 1024 // 假设每个事件平均1KB
    }
}

// MARK: - 统计信息模型

/**
 * 事件存储统计信息
 */
struct EventStatistics: Sendable {
    let totalEvents: Int
    let eventTypeCount: [String: Int]
    let sourceCount: [String: Int]
    let oldestEvent: Date?
    let newestEvent: Date?
    
    var averageEventsPerType: Double {
        guard !eventTypeCount.isEmpty else { return 0 }
        return Double(totalEvents) / Double(eventTypeCount.count)
    }
    
    var timeSpan: TimeInterval? {
        guard let oldest = oldestEvent, let newest = newestEvent else { return nil }
        return newest.timeIntervalSince(oldest)
    }
}