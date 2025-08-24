//
//  BaseActorSimple.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import OSLog

/**
 * Actor消息类型定义
 */
protocol ActorMessage: Sendable {
    var id: UUID { get }
    var timestamp: Date { get }
    var messageType: String { get }
}

/**
 * 默认消息实现
 */
struct DefaultMessage: ActorMessage {
    let id = UUID()
    let timestamp = Date()
    let messageType: String
    let payload: [String: Any]?
    
    init(messageType: String, payload: [String: Any]? = nil) {
        self.messageType = messageType
        self.payload = payload
    }
}

/**
 * Actor状态定义
 */
enum ActorState: Equatable {
    case idle
    case processing
    case error(String)
    case stopped
    
    var isActive: Bool {
        switch self {
        case .idle, .processing:
            return true
        case .error, .stopped:
            return false
        }
    }
    
    static func == (lhs: ActorState, rhs: ActorState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.processing, .processing), (.stopped, .stopped):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/**
 * Actor统计信息
 */
struct ActorStatistics {
    var messagesProcessed: Int = 0
    var messagesQueued: Int = 0
    var averageProcessingTime: TimeInterval = 0
    var lastProcessedAt: Date?
    var errorCount: Int = 0
    var uptime: TimeInterval = 0
    
    mutating func recordProcessing(duration: TimeInterval) {
        messagesProcessed += 1
        averageProcessingTime = (averageProcessingTime + duration) / 2
        lastProcessedAt = Date()
    }
    
    mutating func recordError() {
        errorCount += 1
    }
}

/**
 * 基础Actor协议
 */
protocol ActorProtocol: AnyObject, Sendable {
    /// Actor唯一标识符
    nonisolated var id: UUID { get }
    /// Actor名称
    nonisolated var name: String { get }
    
    /// 获取当前状态
    func getState() async -> ActorState
    /// 获取统计信息
    func getStatistics() async -> ActorStatistics
    
    /// 启动Actor
    func start() async
    /// 停止Actor
    func stop() async
    /// 处理消息
    func tell(_ message: any ActorMessage) async
    /// 请求-响应模式
    func ask<Response: Sendable>(_ message: any ActorMessage) async throws -> Response
}

// MARK: - Actor错误类型

enum ActorError: Error, LocalizedError {
    case actorStopped
    case messageProcessingFailed(Error)
    case invalidMessage(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .actorStopped:
            return "Actor has been stopped"
        case .messageProcessingFailed(let error):
            return "Message processing failed: \(error.localizedDescription)"
        case .invalidMessage(let message):
            return "Invalid message: \(message)"
        case .timeout:
            return "Operation timed out"
        }
    }
}

// MARK: - Actor系统管理器

/**
 * Actor系统管理器
 */
@MainActor
class ActorSystem: ObservableObject {
    static let shared = ActorSystem()
    
    /// 注册的Actor列表
    @Published private(set) var actors: [String: any ActorProtocol] = [:]
    
    private let logger = Logger(subsystem: "fit_wise_ai", category: "ActorSystem")
    
    private init() {
        logger.info("ActorSystem initialized")
    }
    
    /**
     * 注册Actor到系统
     */
    func register(_ actor: any ActorProtocol) async {
        actors[actor.name] = actor
        await actor.start()
        logger.info("Actor registered and started: \(actor.name)")
    }
    
    /**
     * 注销Actor
     */
    func unregister(_ name: String) async {
        if let actor = actors[name] {
            await actor.stop()
            actors.removeValue(forKey: name)
            logger.info("Actor unregistered: \(name)")
        }
    }
    
    /**
     * 获取Actor引用
     */
    func getActor(_ name: String) -> (any ActorProtocol)? {
        return actors[name]
    }
    
    /**
     * 向特定Actor发送消息
     */
    func tell(_ actorName: String, message: any ActorMessage) async {
        guard let actor = actors[actorName] else {
            logger.error("Actor not found: \(actorName)")
            return
        }
        
        await actor.tell(message)
    }
    
    /**
     * 停止所有Actor
     */
    func stopAll() async {
        for actor in actors.values {
            await actor.stop()
        }
        actors.removeAll()
        logger.info("All actors stopped")
    }
    
    /**
     * 获取系统统计信息
     */
    func getSystemStatistics() -> [String: Any] {
        return [
            "totalActors": actors.count,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}