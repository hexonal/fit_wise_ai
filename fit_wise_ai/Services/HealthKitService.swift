//
//  HealthKitService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var healthData = HealthData()
    
    private let healthTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.workoutType()
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("健康数据不可用")
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            print("HealthKit授权失败: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let authorized = healthTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
        
        self.isAuthorized = authorized
    }
    
    @MainActor
    func fetchTodayHealthData() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        async let steps = fetchSteps(from: today, to: tomorrow)
        async let heartRate = fetchLatestHeartRate()
        async let activeEnergy = fetchActiveEnergy(from: today, to: tomorrow)
        async let distance = fetchDistance(from: today, to: tomorrow)
        async let workoutTime = fetchWorkoutTime(from: today, to: tomorrow)
        
        let results = await (steps, heartRate, activeEnergy, distance, workoutTime)
        
        self.healthData = HealthData(
            date: today,
            steps: results.0,
            heartRate: results.1,
            activeEnergyBurned: results.2,
            workoutTime: results.4,
            distanceWalkingRunning: results.3
        )
    }
    
    private func fetchSteps(from startDate: Date, to endDate: Date) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            // 查询结果将在闭包中处理
        }
        
        return await withCheckedContinuation { continuation in
            let statisticsQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(statisticsQuery)
        }
    }
    
    private func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            // 查询结果将在闭包中处理
        }
        
        return await withCheckedContinuation { continuation in
            let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    continuation.resume(returning: heartRate)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(heartRateQuery)
        }
    }
    
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async -> Double {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let energy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchDistance(from startDate: Date, to endDate: Date) async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkoutTime(from startDate: Date, to endDate: Date) async -> TimeInterval {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalDuration = samples?.compactMap { $0 as? HKWorkout }
                    .reduce(0) { $0 + $1.duration } ?? 0
                continuation.resume(returning: totalDuration)
            }
            healthStore.execute(query)
        }
    }
}