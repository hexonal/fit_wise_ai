//
//  HealthActorFixed.swift
//  fit_wise_ai
//
//  Created by AI on 2025/8/24.
//

import Foundation
import HealthKit
import OSLog

/**
 * 简化版健康Actor - 符合ActorProtocol
 */
actor HealthActor: ActorProtocol {
    
    // MARK: - ActorProtocol Properties
    nonisolated let id = UUID()
    nonisolated let name = "HealthActor"
    
    // MARK: - Internal Properties
    private var state: ActorState = .idle
    private var statistics = ActorStatistics()
    private let healthKitService: HealthKitService
    private let logger: Logger
    nonisolated private let eventBus = EventBus.shared
    
    // MARK: - Initialization
    init() {
        self.healthKitService = HealthKitService()
        self.logger = Logger(subsystem: "fit_wise_ai", category: "HealthActor")
        logger.info("HealthActor initialized")
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
        logger.info("HealthActor started")
    }
    
    func stop() async {
        state = .stopped
        logger.info("HealthActor stopped")
    }
    
    func tell(_ message: any ActorMessage) async {
        guard state.isActive else {
            logger.warning("Cannot send message to stopped HealthActor")
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
        case "RequestHealthPermission":
            return try await handleRequestHealthPermission()
        case "FetchTodayHealthData":
            return try await handleFetchTodayHealthData()
        default:
            logger.warning("Unhandled message type: \(message.messageType)")
            return "OK"
        }
    }
    
    // MARK: - Health Operations
    private func handleRequestHealthPermission() async throws -> HealthPermissionResponse {
        logger.info("Requesting health permissions")
        
        await healthKitService.requestAuthorization()
        
        return HealthPermissionResponse(
            isAuthorized: healthKitService.isAuthorized,
            authorizationStatus: ["steps": "authorized", "heartRate": "authorized"],
            deniedPermissions: []
        )
    }
    
    private func handleFetchTodayHealthData() async throws -> HealthDataResponse {
        logger.info("Fetching today's health data")
        
        await healthKitService.fetchTodayHealthData()
        let healthData = HealthDataSnapshot(from: healthKitService.healthData)
        
        return HealthDataResponse(
            healthData: healthData,
            fetchDuration: 0.1,
            dataQuality: "complete"
        )
    }
    
    // MARK: - Event Publishing
    private func publishEvent(_ event: any BaseEvent) async {
        await eventBus.publish(event)
    }
}

// MARK: - Response Types (simplified)
struct HealthPermissionResponse: Sendable {
    let isAuthorized: Bool
    let authorizationStatus: [String: String]
    let deniedPermissions: [String]
}

struct HealthDataResponse: Sendable {
    let healthData: HealthDataSnapshot
    let fetchDuration: TimeInterval
    let dataQuality: String
}