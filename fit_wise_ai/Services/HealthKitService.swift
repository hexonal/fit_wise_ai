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
    @Published var weeklyHealthData: [HealthData] = []
    
    // 扩展健康数据类型，包含更多常用指标
    private let healthTypesToRead: Set<HKObjectType> = [
        // 活动数据
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
        
        // 心血管数据
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        
        // 身体指标
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        
        // 睡眠和休息
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        
        // 运动数据
        HKObjectType.workoutType(),
        
        // 营养数据
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
        
        // 其他健康指标
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .vo2Max)!
    ]
    
    init() {
        print("🟢 HealthKitService: 初始化")
        Task { @MainActor in
            print("🟢 HealthKitService: 检查初始授权状态")
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        print("🟡 HealthKitService: 开始请求HealthKit授权")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🔴 HealthKitService: 设备不支持HealthKit")
            await MainActor.run { self.isAuthorized = false }
            return
        }
        
        // 使用核心数据类型集合，避免请求过多权限导致被拒绝
        let coreHealthTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        
        do {
            print("🟡 HealthKitService: 请求核心权限，数据类型数量: \(coreHealthTypes.count)")
            
            // 只请求核心的健康数据类型
            try await healthStore.requestAuthorization(toShare: [], read: coreHealthTypes)
            
            print("🟢 HealthKitService: 权限请求完成")
            
            // 增加延迟，等待权限状态更新
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            await MainActor.run {
                self.checkAuthorizationStatus()
                print("🟢 HealthKitService: 授权状态已更新: \(self.isAuthorized)")
            }
            
        } catch {
            print("🔴 HealthKitService: 权限请求失败: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }
    
    @MainActor
    func checkAuthorizationStatus() {
        print("🟡 checkAuthorizationStatus: 开始检查授权状态")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🔴 checkAuthorizationStatus: HealthKit不可用")
            self.isAuthorized = false
            return
        }
        
        // 检查核心数据类型的授权状态
        let coreTypes: [HKObjectType] = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        var deniedCount = 0
        var notDeterminedCount = 0
        var authorizedCount = 0
        
        for type in coreTypes {
            let status = healthStore.authorizationStatus(for: type)
            print("🟡 checkAuthorizationStatus: \(type.identifier) 状态: \(status.rawValue)")
            
            switch status {
            case .notDetermined:
                notDeterminedCount += 1
                print("🟡 checkAuthorizationStatus: \(type.identifier) - 权限未决定")
            case .sharingDenied:
                deniedCount += 1
                print("🔴 checkAuthorizationStatus: \(type.identifier) - 权限被拒绝")
            case .sharingAuthorized:
                authorizedCount += 1
                print("🟢 checkAuthorizationStatus: \(type.identifier) - 权限已授权")
            @unknown default:
                print("🟠 checkAuthorizationStatus: \(type.identifier) - 未知授权状态: \(status.rawValue)")
            }
        }
        
        // 改进的授权检查逻辑：
        // 1. 如果有任何权限被授权，就认为可以使用（即使部分被拒绝）
        // 2. 只有当所有权限都被拒绝或都未决定时，才认为未授权
        
        let allNotDetermined = notDeterminedCount == coreTypes.count
        let allDenied = deniedCount == coreTypes.count
        let hasAnyAuthorized = authorizedCount > 0
        
        var authorized = false
        
        if hasAnyAuthorized {
            // 有任何权限被授权，就可以使用
            authorized = true
            print("🟢 checkAuthorizationStatus: \(authorizedCount)个权限已授权，可以使用")
        } else if allNotDetermined {
            // 所有权限都未决定，需要请求权限
            authorized = false
            print("🟡 checkAuthorizationStatus: 所有权限未决定，需要请求权限")
        } else if allDenied {
            // 所有权限都被拒绝
            authorized = false
            print("🔴 checkAuthorizationStatus: 所有权限被拒绝")
        } else {
            // 混合状态（部分未决定，部分拒绝）
            authorized = false
            print("🟠 checkAuthorizationStatus: 混合状态，无可用权限")
        }
        
        print("🟢 checkAuthorizationStatus: 最终授权状态: \(authorized) (拒绝:\(deniedCount), 未决定:\(notDeterminedCount), 已授权:\(authorizedCount))")
        self.isAuthorized = authorized
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    func fetchTodayHealthData() async {
        print("🟡 HealthKitService: 开始获取今日健康数据")
        
        // 在获取数据前，先确保权限状态是最新的
        checkAuthorizationStatus()
        
        guard isAuthorized else {
            print("🔴 HealthKitService: 权限未授权，无法获取数据")
            self.healthData = HealthData() // 返回空数据
            return
        }
        
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
        
        print("🟢 HealthKitService: 今日数据获取完成 - 步数:\(results.0), 心率:\(results.1 ?? 0), 卡路里:\(results.2)")
    }
    
    @MainActor
    func fetchWeeklyHealthData() async {
        print("🟡 HealthKitService: 开始获取7天历史数据")
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        var results: [HealthData] = []
        
        // 使用TaskGroup并发获取7天数据
        await withTaskGroup(of: HealthData?.self) { group in
            for i in 0..<7 {
                let dayEnd = calendar.date(byAdding: .day, value: -i, to: endDate)!
                let dayStart = calendar.startOfDay(for: dayEnd)
                let dayNext = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    
                    async let steps = self.fetchSteps(from: dayStart, to: dayNext)
                    async let heartRate = self.fetchAverageHeartRate(from: dayStart, to: dayNext)
                    async let activeEnergy = self.fetchActiveEnergy(from: dayStart, to: dayNext)
                    async let distance = self.fetchDistance(from: dayStart, to: dayNext)
                    async let workoutTime = self.fetchWorkoutTime(from: dayStart, to: dayNext)
                    
                    let dayResults = await (steps, heartRate, activeEnergy, distance, workoutTime)
                    
                    return HealthData(
                        date: dayStart,
                        steps: dayResults.0,
                        heartRate: dayResults.1,
                        activeEnergyBurned: dayResults.2,
                        workoutTime: dayResults.4,
                        distanceWalkingRunning: dayResults.3
                    )
                }
            }
            
            for await result in group {
                if let data = result {
                    results.append(data)
                }
            }
        }
        
        // 按日期排序
        self.weeklyHealthData = results.sorted { $0.date < $1.date }
        print("🟢 HealthKitService: 7天历史数据获取完成，共\(results.count)天")
    }
    
    // MARK: - Private Data Fetching Methods
    
    private func fetchSteps(from startDate: Date, to endDate: Date) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { 
            print("🔴 fetchSteps: 无法创建stepCount类型")
            return 0 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("🔴 fetchSteps: 查询错误: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { 
            print("🔴 fetchLatestHeartRate: 无法创建heartRate类型")
            return nil 
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("🔴 fetchLatestHeartRate: 查询错误: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    continuation.resume(returning: heartRate)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async -> Double {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { 
            print("🔴 fetchActiveEnergy: 无法创建activeEnergyBurned类型")
            return 0 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("🔴 fetchActiveEnergy: 查询错误: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let energy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchDistance(from startDate: Date, to endDate: Date) async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { 
            print("🔴 fetchDistance: 无法创建distanceWalkingRunning类型")
            return 0 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("🔴 fetchDistance: 查询错误: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkoutTime(from startDate: Date, to endDate: Date) async -> TimeInterval {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("🔴 fetchWorkoutTime: 查询错误: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let totalDuration = samples?.compactMap { $0 as? HKWorkout }
                    .reduce(0) { $0 + $1.duration } ?? 0
                continuation.resume(returning: totalDuration)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchAverageHeartRate(from startDate: Date, to endDate: Date) async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { 
            print("🔴 fetchAverageHeartRate: 无法创建heartRate类型")
            return nil 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    print("🔴 fetchAverageHeartRate: 查询错误: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let averageHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: averageHeartRate)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Additional Health Data Methods
    
    /// 重新检查并同步权限状态
    @MainActor
    func refreshAuthorizationStatus() async {
        print("🟡 HealthKitService: 重新检查权限状态")
        
        // 先检查当前状态
        checkAuthorizationStatus()
        
        // 如果检测到未授权，尝试重新请求
        if !isAuthorized {
            print("🟡 HealthKitService: 未检测到授权，尝试重新请求")
            await requestAuthorization()
        }
        
        // 再次检查状态
        checkAuthorizationStatus()
        print("🟢 HealthKitService: 权限状态刷新完成: \(isAuthorized)")
    }
    
    /// 强制重新请求所有权限（用于权限被拒绝后的重试）
    func forceRequestAllPermissions() async {
        print("🟡 HealthKitService: 强制重新请求所有权限")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🔴 HealthKitService: 设备不支持HealthKit")
            await MainActor.run { self.isAuthorized = false }
            return
        }
        
        // 分批请求权限，避免一次性请求过多导致被拒绝
        let batch1: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        let batch2: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let batch3: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]
        
        do {
            // 分批请求权限
            print("🟡 HealthKitService: 请求第一批权限（步数、距离）")
            try await healthStore.requestAuthorization(toShare: [], read: batch1)
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            
            print("🟡 HealthKitService: 请求第二批权限（心率、卡路里）")
            try await healthStore.requestAuthorization(toShare: [], read: batch2)
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            
            print("🟡 HealthKitService: 请求第三批权限（运动）")
            try await healthStore.requestAuthorization(toShare: [], read: batch3)
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            
            await MainActor.run {
                self.checkAuthorizationStatus()
                print("🟢 HealthKitService: 分批权限请求完成: \(self.isAuthorized)")
            }
            
        } catch {
            print("🔴 HealthKitService: 分批权限请求失败: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }
    
    /// 获取用户的基本身体信息（身高、体重等）
    func fetchBasicBodyInfo() async -> (height: Double?, weight: Double?) {
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
        async let height = fetchMostRecentQuantity(for: heightType, unit: HKUnit.meter())
        async let weight = fetchMostRecentQuantity(for: weightType, unit: HKUnit.gramUnit(with: .kilo))
        
        let results = await (height, weight)
        return (results.0, results.1)
    }
    
    /// 验证HealthKit集成状态的诊断方法
    func performHealthKitDiagnostics() async -> String {
        var diagnostics = "🔍 HealthKit集成诊断报告\n\n"
        
        // 1. 检查HealthKit可用性
        diagnostics += "1. HealthKit可用性检查\n"
        if HKHealthStore.isHealthDataAvailable() {
            diagnostics += "   ✅ HealthKit可用\n"
        } else {
            diagnostics += "   ❌ HealthKit不可用\n"
            return diagnostics
        }
        
        // 2. 检查授权状态
        diagnostics += "\n2. 权限授权状态\n"
        let coreTypes: [HKObjectType] = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        for type in coreTypes {
            let status = healthStore.authorizationStatus(for: type)
            let statusText = switch status {
            case .notDetermined: "未决定"
            case .sharingDenied: "已拒绝"
            case .sharingAuthorized: "已授权"
            @unknown default: "未知状态(\(status.rawValue))"
            }
            diagnostics += "   \(type.identifier): \(statusText)\n"
        }
        
        // 3. 尝试获取实际数据
        diagnostics += "\n3. 数据获取测试\n"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let steps = await fetchSteps(from: today, to: tomorrow)
        let heartRate = await fetchLatestHeartRate()
        let activeEnergy = await fetchActiveEnergy(from: today, to: tomorrow)
        let distance = await fetchDistance(from: today, to: tomorrow)
        
        diagnostics += "   步数: \(steps)步 \(steps > 0 ? "✅" : "⚠️")\n"
        diagnostics += "   心率: \(heartRate.map { String(format: "%.0f", $0) + "次/分" } ?? "无数据") \(heartRate != nil ? "✅" : "⚠️")\n"
        diagnostics += "   活动卡路里: \(String(format: "%.0f", activeEnergy))卡 \(activeEnergy > 0 ? "✅" : "⚠️")\n"
        diagnostics += "   步行距离: \(String(format: "%.1f", distance/1000))公里 \(distance > 0 ? "✅" : "⚠️")\n"
        
        // 4. 总体状态评估
        diagnostics += "\n4. 总体状态评估\n"
        let hasData = steps > 0 || heartRate != nil || activeEnergy > 0 || distance > 0
        if hasData {
            diagnostics += "   ✅ HealthKit集成正常，成功获取到健康数据\n"
        } else {
            diagnostics += "   ⚠️  未能获取到健康数据，可能需要:\n"
            diagnostics += "      - 在iPhone健康app中授权数据访问\n"
            diagnostics += "      - 确保有运动数据记录\n"
            diagnostics += "      - 检查Apple Watch是否正确同步\n"
        }
        
        return diagnostics
    }
    
    /// 通用方法：获取最新的数量类型数据
    private func fetchMostRecentQuantity(for quantityType: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("🔴 fetchMostRecentQuantity: 查询错误 \(quantityType.identifier): \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                if let sample = samples?.first as? HKQuantitySample {
                    let value = sample.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }
}