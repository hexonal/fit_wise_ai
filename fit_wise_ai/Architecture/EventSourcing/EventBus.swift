//
//  EventBus.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import Combine
import OSLog

/**
 * Event Bus - 事件总线
 * 
 * 负责事件的分发和路由，实现发布-订阅模式
 * 支持同步和异步事件处理，类型安全的事件订阅
 */
@MainActor
class EventBus: ObservableObject {
    
    // MARK: - Properties
    
    /// 事件处理器注册表
    private var handlers: [String: [any EventHandler]] = [:]
    /// 事件发布器
    private let eventSubject = PassthroughSubject<any BaseEvent, Never>()
    /// 日志记录器
    private let logger = Logger(subsystem: "fit_wise_ai", category: "EventBus")
    /// 取消订阅集合
    private var cancellables = Set<AnyCancellable>()
    /// 事件存储引用
    private let eventStore = EventStore.shared
    /// 处理统计信息
    @Published var processingStats = EventProcessingStats()
    
    // MARK: - 单例模式
    
    static let shared = EventBus()
    
    private init() {
        setupEventStoreSubscription()
        logger.info("EventBus initialized")
    }
    
    // MARK: - 事件发布
    
    /**
     * 发布事件到系统
     */
    func publish<T: BaseEvent>(_ event: T) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 存储事件到EventStore
        await eventStore.append(event)
        
        // 通过内部事件总线分发
        eventSubject.send(event)
        
        // 更新统计信息
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await updateProcessingStats(eventType: event.eventType, processingTime: processingTime)
        
        logger.info("Event published: \(event.eventType) from \(event.source)")
    }
    
    /**
     * 批量发布事件
     */
    func publishBatch<T: BaseEvent>(_ events: [T]) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 批量存储到EventStore
        await eventStore.appendBatch(events)
        
        // 分发所有事件
        for event in events {
            eventSubject.send(event)
        }
        
        // 更新统计信息
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await updateBatchProcessingStats(eventCount: events.count, processingTime: processingTime)
        
        logger.info("Batch published: \(events.count) events")
    }
    
    // MARK: - 事件订阅
    
    /**
     * 订阅特定类型的事件
     */
    func subscribe<T: BaseEvent>(
        to eventType: T.Type,
        handler: @escaping (T) async -> EventHandlingResult
    ) {
        let eventTypeName = String(describing: eventType)
        let wrappedHandler = TypedEventHandler(handler: handler)
        
        if handlers[eventTypeName] == nil {
            handlers[eventTypeName] = []
        }
        handlers[eventTypeName]?.append(wrappedHandler)
        
        logger.info("Handler registered for event type: \(eventTypeName)")
    }
    
    /**
     * 订阅多种事件类型
     */
    func subscribe<T: BaseEvent>(
        to eventTypes: [T.Type],
        handler: @escaping (T) async -> EventHandlingResult
    ) {
        for eventType in eventTypes {
            subscribe(to: eventType, handler: handler)
        }
    }
    
    /**
     * 通过Combine订阅事件流
     */
    func eventPublisher<T: BaseEvent>(for eventType: T.Type) -> AnyPublisher<T, Never> {
        return eventSubject
            .compactMap { $0 as? T }
            .eraseToAnyPublisher()
    }
    
    /**
     * 订阅所有事件
     */
    func subscribeToAll(handler: @escaping (any BaseEvent) async -> EventHandlingResult) {
        let wrappedHandler = GenericEventHandler(handler: handler)
        
        if handlers["*"] == nil {
            handlers["*"] = []
        }
        handlers["*"]?.append(wrappedHandler)
        
        logger.info("Universal event handler registered")
    }
    
    // MARK: - 事件处理
    
    /**
     * 设置EventStore订阅
     */
    private func setupEventStoreSubscription() {
        // 从EventStore订阅所有新事件
        Task { [weak self] in
            guard let self = self else { return }
            
            // 这里可以从EventStore获取事件流
            // 目前直接处理内部发布的事件
            await self.setupInternalEventHandling()
        }
    }
    
    /**
     * 设置内部事件处理
     */
    private func setupInternalEventHandling() async {
        eventSubject
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.handleEvent(event)
                }
            }
            .store(in: &cancellables)
    }
    
    /**
     * 处理接收到的事件
     */
    private func handleEvent(_ event: any BaseEvent) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        let eventType = event.eventType
        
        // 获取特定类型的处理器
        let specificHandlers = handlers[eventType] ?? []
        
        // 获取通用处理器
        let universalHandlers = handlers["*"] ?? []
        
        let allHandlers = specificHandlers + universalHandlers
        
        guard !allHandlers.isEmpty else {
            logger.debug("No handlers found for event type: \(eventType)")
            return
        }
        
        // 并发执行所有处理器
        await withTaskGroup(of: Void.self) { group in
            for handler in allHandlers {
                group.addTask {
                    let result = await handler.handle(event)
                    
                    switch result {
                    case .success:
                        self.logger.debug("Event handled successfully: \(eventType)")
                    case .failure(let error):
                        self.logger.error("Event handling failed: \(eventType), error: \(error.localizedDescription)")
                    case .ignored(let reason):
                        self.logger.debug("Event ignored: \(eventType), reason: \(reason)")
                    }
                }
            }
        }
        
        // 更新处理统计
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await updateHandlingStats(eventType: eventType, handlerCount: allHandlers.count, processingTime: processingTime)
        
        logger.info("Event \(eventType) processed by \(allHandlers.count) handlers in \(String(format: "%.2f", processingTime * 1000))ms")
    }
    
    // MARK: - 统计信息更新
    
    private func updateProcessingStats(eventType: String, processingTime: TimeInterval) async {
        processingStats.totalEventsPublished += 1
        processingStats.averagePublishTime = (processingStats.averagePublishTime + processingTime) / 2
        processingStats.eventTypeStats[eventType, default: EventTypeStats()].publishCount += 1
    }
    
    private func updateBatchProcessingStats(eventCount: Int, processingTime: TimeInterval) async {
        processingStats.totalEventsPublished += eventCount
        processingStats.totalBatchesPublished += 1
        processingStats.averageBatchPublishTime = (processingStats.averageBatchPublishTime + processingTime) / 2
    }
    
    private func updateHandlingStats(eventType: String, handlerCount: Int, processingTime: TimeInterval) async {
        processingStats.totalEventsHandled += 1
        processingStats.averageHandlingTime = (processingStats.averageHandlingTime + processingTime) / 2
        
        var eventStats = processingStats.eventTypeStats[eventType, default: EventTypeStats()]
        eventStats.handleCount += 1
        eventStats.averageHandlerCount = Double(handlerCount)
        eventStats.averageHandlingTime = (eventStats.averageHandlingTime + processingTime) / 2
        processingStats.eventTypeStats[eventType] = eventStats
    }
    
    // MARK: - 查询和管理
    
    /**
     * 获取已注册的事件类型
     */
    func getRegisteredEventTypes() -> [String] {
        return Array(handlers.keys)
    }
    
    /**
     * 获取特定事件类型的处理器数量
     */
    func getHandlerCount(for eventType: String) -> Int {
        return handlers[eventType]?.count ?? 0
    }
    
    /**
     * 清除所有处理器
     */
    func clearAllHandlers() {
        handlers.removeAll()
        logger.info("All event handlers cleared")
    }
    
    /**
     * 清除特定事件类型的处理器
     */
    func clearHandlers(for eventType: String) {
        handlers.removeValue(forKey: eventType)
        logger.info("Handlers cleared for event type: \(eventType)")
    }
}

// MARK: - Event Handler 协议和实现

/**
 * 事件处理器协议
 */
protocol EventHandler: Sendable {
    func handle(_ event: any BaseEvent) async -> EventHandlingResult
}

/**
 * 类型化事件处理器
 */
struct TypedEventHandler<T: BaseEvent>: EventHandler {
    let handler: (T) async -> EventHandlingResult
    
    func handle(_ event: any BaseEvent) async -> EventHandlingResult {
        guard let typedEvent = event as? T else {
            return .ignored(reason: "Event type mismatch")
        }
        return await handler(typedEvent)
    }
}

/**
 * 通用事件处理器
 */
struct GenericEventHandler: EventHandler {
    let handler: (any BaseEvent) async -> EventHandlingResult
    
    func handle(_ event: any BaseEvent) async -> EventHandlingResult {
        return await handler(event)
    }
}

// MARK: - 统计信息模型

/**
 * 事件处理统计信息
 */
struct EventProcessingStats {
    var totalEventsPublished: Int = 0
    var totalEventsHandled: Int = 0
    var totalBatchesPublished: Int = 0
    var averagePublishTime: TimeInterval = 0
    var averageHandlingTime: TimeInterval = 0
    var averageBatchPublishTime: TimeInterval = 0
    var eventTypeStats: [String: EventTypeStats] = [:]
    
    var successRate: Double {
        guard totalEventsPublished > 0 else { return 0 }
        return Double(totalEventsHandled) / Double(totalEventsPublished)
    }
}

/**
 * 事件类型统计信息
 */
struct EventTypeStats {
    var publishCount: Int = 0
    var handleCount: Int = 0
    var averageHandlerCount: Double = 0
    var averageHandlingTime: TimeInterval = 0
    
    var handlingRate: Double {
        guard publishCount > 0 else { return 0 }
        return Double(handleCount) / Double(publishCount)
    }
}