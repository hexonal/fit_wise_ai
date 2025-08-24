//
//  AIActor.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import OSLog

/**
 * 简化版AI Actor - 符合ActorProtocol
 */
actor AIActor: ActorProtocol {
    
    // MARK: - ActorProtocol Properties
    nonisolated let id = UUID()
    nonisolated let name = "AIActor"
    
    // MARK: - Internal Properties
    private var state: ActorState = .idle
    private var statistics = ActorStatistics()
    private let logger: Logger
    nonisolated private let eventBus = EventBus.shared
    
    // MARK: - Initialization
    init() {
        self.logger = Logger(subsystem: "fit_wise_ai", category: "AIActor")
        logger.info("AIActor initialized")
    }
    
    // MARK: - ActorProtocol Methods
    func getState() async -> ActorState {
        return state
    }
    
    func getStatistics() async -> ActorStatistics {
        return statistics
    }
    
    func start() async {
        state = .idle
        logger.info("AIActor started")
    }
    
    func stop() async {
        state = .stopped
        logger.info("AIActor stopped")
    }
    
    func tell(_ message: any ActorMessage) async {
        guard state.isActive else {
            logger.warning("Cannot send message to stopped AIActor")
            return
        }
        
        do {
            let _ = try await handleMessage(message)
        } catch {
            statistics.recordError()
            logger.error("Message processing failed: \(error)")
        }
    }
    
    func ask<Response: Sendable>(_ message: any ActorMessage) async throws -> Response {
        guard state.isActive else {
            throw ActorError.actorStopped
        }
        
        let response = try await handleMessage(message)
        if let typedResponse = response as? Response {
            return typedResponse
        } else {
            throw ActorError.invalidMessage("Response type mismatch")
        }
    }
    
    // MARK: - Message Handling
    private func handleMessage(_ message: any ActorMessage) async throws -> Any {
        let startTime = CFAbsoluteTimeGetCurrent()
        state = .processing
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            statistics.recordProcessing(duration: duration)
            state = .idle
        }
        
        switch message.messageType {
        case "GenerateAIAdvice":
            return try await handleGenerateAIAdvice()
        default:
            logger.warning("Unhandled message type: \(message.messageType)")
            return "OK"
        }
    }
    
    // MARK: - AI Operations
    private func handleGenerateAIAdvice() async throws -> SimpleAIResponse {
        logger.info("Generating AI advice")
        
        // 简化的AI建议生成
        let advice = [
            "保持每天至少30分钟运动",
            "均衡膳食，多吃蔬菜水果",
            "保证7-8小时优质睡眠"
        ]
        
        return SimpleAIResponse(
            advice: advice,
            confidence: 0.8
        )
    }
    
    // MARK: - Event Publishing
    private func publishEvent(_ event: any BaseEvent) async {
        await eventBus.publish(event)
    }
}

// MARK: - Simple Response Types
struct SimpleAIResponse: Sendable {
    let advice: [String]
    let confidence: Double
}