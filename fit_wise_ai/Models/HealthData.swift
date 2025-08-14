//
//  HealthData.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation
import HealthKit

struct HealthData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let heartRate: Double?
    let activeEnergyBurned: Double
    let workoutTime: TimeInterval
    let distanceWalkingRunning: Double
    
    init(date: Date = Date(),
         steps: Int = 0,
         heartRate: Double? = nil,
         activeEnergyBurned: Double = 0,
         workoutTime: TimeInterval = 0,
         distanceWalkingRunning: Double = 0) {
        self.date = date
        self.steps = steps
        self.heartRate = heartRate
        self.activeEnergyBurned = activeEnergyBurned
        self.workoutTime = workoutTime
        self.distanceWalkingRunning = distanceWalkingRunning
    }
}

extension HealthData {
    var formattedSteps: String {
        return "\(steps)"
    }
    
    var formattedHeartRate: String {
        guard let heartRate = heartRate else { return "--" }
        return String(format: "%.0f", heartRate)
    }
    
    var formattedActiveEnergy: String {
        return String(format: "%.0f", activeEnergyBurned)
    }
    
    var formattedWorkoutTime: String {
        let hours = Int(workoutTime) / 3600
        let minutes = (Int(workoutTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDistance: String {
        return String(format: "%.1f", distanceWalkingRunning / 1000)
    }
}