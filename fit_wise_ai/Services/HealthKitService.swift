//
//  HealthKitService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation
import HealthKit

/// HealthKit权限状态枚举（基于Apple官方文档）
enum HealthKitAuthorizationStatus {
    case notDetermined      // 0 - 未决定
    case sharingDenied      // 1 - 被拒绝  
    case sharingAuthorized  // 2 - 已授权
    
    /// 从HKAuthorizationStatus转换
    static func from(_ hkStatus: HKAuthorizationStatus) -> HealthKitAuthorizationStatus {
        switch hkStatus {
        case .notDetermined:
            return .notDetermined
        case .sharingDenied:
            return .sharingDenied
        case .sharingAuthorized:
            return .sharingAuthorized
        @unknown default:
            return .notDetermined
        }
    }
}

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var healthData = HealthData()
    @Published var weeklyHealthData: [HealthData] = []
    @Published var authorizationRequestInProgress = false
    @Published var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    
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
        // 不在init时检查权限状态，等待UI主动触发
        // 这样可以确保权限检查在适当的时机进行
    }
    
    // MARK: - Authorization
    
    /// HealthKit权限请求方法
    /// 注意：对于读权限，用户授权后需要通过数据读取来验证，而非依赖authorizationStatus
    func requestAuthorization() async {
        await MainActor.run {
            authorizationRequestInProgress = true
        }
        
        print("🟡 HealthKitService: 开始请求HealthKit读权限")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🔴 HealthKitService: 设备不支持HealthKit")
            await MainActor.run { 
                self.isAuthorized = false
                self.authorizationRequestInProgress = false
                self.authorizationStatus = .sharingDenied
            }
            return
        }
        
        // 请求基本健康数据的读权限（包括运动数据）
        let healthTypesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType() // 添加运动数据权限
        ]
        
        do {
            print("🟡 HealthKitService: 调用requestAuthorization API")
            
            // 请求读权限（toShare为空，只要求read权限）
            try await healthStore.requestAuthorization(toShare: [], read: healthTypesToRead)
            
            print("🟢 HealthKitService: 权限对话框已显示并处理完成")
            
            // 权限请求完成后，通过实际数据读取验证权限状态
            await checkCurrentAuthorizationStatus()
            
        } catch {
            print("🔴 HealthKitService: 权限请求API调用失败: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationRequestInProgress = false
                self.authorizationStatus = .sharingDenied
            }
        }
    }
    
    /// 检查HealthKit读权限状态
    /// 
    /// ⚠️ 重要：对于HealthKit读权限，authorizationStatus可能不准确！
    /// Apple的隐私保护机制导致读权限的authorizationStatus可能始终返回.notDetermined
    /// 即使用户已经授权。正确的方法是尝试读取数据来验证权限。
    @MainActor 
    func checkCurrentAuthorizationStatus() async {
        print("🟡 HealthKitService: 检查HealthKit读权限状态")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🔴 HealthKitService: HealthKit不可用")
            self.isAuthorized = false
            self.authorizationStatus = .sharingDenied
            self.authorizationRequestInProgress = false
            return
        }
        
        // 对于HealthKit读权限，正确的检查方式是尝试读取数据
        // authorizationStatus对读权限可能不准确（隐私保护机制）
        print("🟡 HealthKitService: 通过数据读取验证权限...")
        
        let hasReadAccess = await testHealthKitReadAccess()
        
        if hasReadAccess {
            print("🟢 HealthKitService: HealthKit读权限有效")
            self.isAuthorized = true
            self.authorizationStatus = .sharingAuthorized
        } else {
            print("🔴 HealthKitService: HealthKit读权限无效")
            self.isAuthorized = false
            self.authorizationStatus = .sharingDenied
        }
        
        self.authorizationRequestInProgress = false
        print("🟢 HealthKitService: 权限验证完成 - 最终状态: \(self.isAuthorized)")
    }
    
    /// 测试HealthKit读权限的有效性
    /// 
    /// 这是验证HealthKit读权限的正确方法。由于Apple的隐私保护机制，
    /// authorizationStatus对读权限可能不准确，唯一可靠的方法是尝试读取数据。
    private func testHealthKitReadAccess() async -> Bool {
        print("🔍 HealthKitService: 测试读权限...")
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("🔴 HealthKitService: 无法创建stepCount类型")
            return false
        }
        
        // 创建一个简单的查询来测试权限
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    let nsError = error as NSError
                    print("🔍 HealthKitService: 读权限测试错误: \(error.localizedDescription) (Domain: \(nsError.domain), Code: \(nsError.code))")
                    
                    // 检查是否是权限错误
                    if nsError.domain == HKErrorDomain && nsError.code == HKError.errorAuthorizationDenied.rawValue {
                        print("🔴 HealthKitService: 确认无读权限 - 权限被明确拒绝")
                        continuation.resume(returning: false)
                    } else if nsError.domain == HKErrorDomain && nsError.code == 11 {
                        // 错误代码11表示"No data available" - 这通常意味着有权限但无数据
                        print("🟡 HealthKitService: 无可用数据，但有读权限（模拟器常见情况）")
                        continuation.resume(returning: true)
                    } else {
                        // 其他错误，保守判断为有权限
                        print("🟡 HealthKitService: 其他错误类型，假定有权限")
                        continuation.resume(returning: true)
                    }
                } else {
                    print("🟢 HealthKitService: 读权限测试成功，有数据可读取")
                    continuation.resume(returning: true)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    
    /// 检查应用所需的全部HealthKit权限状态
    /// 
    /// ⚠️ 注意：由于HealthKit读权限的隐私保护机制，authorizationStatus可能不准确。
    /// 此方法仅作为UI显示的参考，实际权限状态应通过testHealthKitReadAccess()验证。
    /// 
    /// 检查的核心权限：
    /// - 步数 (stepCount): 用于追踪日常活动量
    /// - 步行+跑步距离 (distanceWalkingRunning): 用于计算运动距离
    /// - 活动能量 (activeEnergyBurned): 用于追踪卡路里消耗
    /// - 心率 (heartRate): 用于监测心血管健康状况
    /// 
    /// - Returns: 可能缺失权限的HKObjectType数组。仅供UI显示参考。
    func checkRequiredPermissions() -> [HKObjectType] {
        // 如果已通过实际数据读取验证有权限，返回空数组
        if isAuthorized {
            return []
        }
        
        // 定义应用正常运行所需的核心HealthKit权限
        let requiredTypes: [HKObjectType] = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // 如果实际权限检查失败，则假定需要所有权限
        // 这样可以确保UI能正确显示权限请求界面
        return requiredTypes
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    func fetchTodayHealthData() async {
        print("🟡 HealthKitService: 开始获取今日健康数据")
        
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
        let _ = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
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
        print("🟡 fetchSteps: 开始获取步数数据 from \(startDate) to \(endDate)")
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { 
            print("🔴 fetchSteps: 无法创建stepCount类型")
            return 0 
        }
        
        // 检查步数的权限状态
        let authStatus = healthStore.authorizationStatus(for: stepType)
        print("🟡 fetchSteps: 步数权限状态: \(authStatus.rawValue)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    let nsError = error as NSError
                    print("🔴 fetchSteps: 查询错误详情 - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(error.localizedDescription)")
                    
                    // 详细错误分析
                    if nsError.domain == HKErrorDomain {
                        switch nsError.code {
                        case 5: // HKErrorAuthorizationDenied
                            print("🔴 fetchSteps: 权限被拒绝")
                        case 11: // HKErrorNoData  
                            print("📱 fetchSteps: 无数据可用（模拟器常见）")
                        default:
                            print("🔴 fetchSteps: 其他HealthKit错误: \(nsError.code)")
                        }
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                print("🟢 fetchSteps: 查询成功，步数: \(steps)")
                
                continuation.resume(returning: Int(steps))
            }
            
            print("🟡 fetchSteps: 执行查询...")
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
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain && nsError.code == 11 {
                        print("📱 fetchLatestHeartRate: 模拟器无数据（正常情况）")
                    } else {
                        print("🔴 fetchLatestHeartRate: 查询错误: \(error)")
                    }
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
        print("🟡 fetchActiveEnergy: 开始获取活动能量数据 from \(startDate) to \(endDate)")
        
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { 
            print("🔴 fetchActiveEnergy: 无法创建activeEnergyBurned类型")
            return 0 
        }
        
        // 检查活动能量的权限状态
        let authStatus = healthStore.authorizationStatus(for: activeEnergyType)
        print("🟡 fetchActiveEnergy: 活动能量权限状态: \(authStatus.rawValue)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    let nsError = error as NSError
                    print("🔴 fetchActiveEnergy: 查询错误详情 - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(error.localizedDescription)")
                    
                    // 详细错误分析
                    if nsError.domain == HKErrorDomain {
                        switch nsError.code {
                        case 5: // HKErrorAuthorizationDenied
                            print("🔴 fetchActiveEnergy: 权限被拒绝")
                        case 11: // HKErrorNoData  
                            print("📱 fetchActiveEnergy: 无数据可用（模拟器常见）")
                        default:
                            print("🔴 fetchActiveEnergy: 其他HealthKit错误: \(nsError.code)")
                        }
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let energy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                print("🟢 fetchActiveEnergy: 查询成功，活动能量: \(energy) kcal")
                
                continuation.resume(returning: energy)
            }
            
            print("🟡 fetchActiveEnergy: 执行查询...")
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
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain && nsError.code == 11 {
                        print("📱 fetchDistance: 模拟器无数据（正常情况）")
                    } else {
                        print("🔴 fetchDistance: 查询错误: \(error)")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance)
            }
            healthStore.execute(query)
        }
    }
    
    /// 获取指定时间段内的运动时长
    /// 
    /// 此方法尝试从HealthKit获取用户的运动记录总时长。
    /// 如果没有真实的运动记录，会基于步数和活动能量数据进行计算。
    /// 
    /// 计算策略：
    /// 1. 首先尝试获取真实的HKWorkout数据
    /// 2. 如果没有运动记录，基于步数和活动能量计算运动时长
    /// 3. 如果都没有数据，返回0（不进行估算）
    /// 
    /// - Parameters:
    ///   - startDate: 查询开始时间
    ///   - endDate: 查询结束时间
    /// - Returns: 运动总时长（秒），基于实际数据计算
    private func fetchWorkoutTime(from startDate: Date, to endDate: Date) async -> TimeInterval {
        print("🟡 fetchWorkoutTime: 开始获取运动时长数据 from \(startDate) to \(endDate)")
        
        // 首先尝试获取真实的运动数据
        let actualWorkoutTime = await fetchActualWorkoutTime(from: startDate, to: endDate)
        
        // 如果获取到真实数据，直接返回
        if actualWorkoutTime > 0 {
            print("✅ fetchWorkoutTime: 获取到真实运动时长: \(actualWorkoutTime/60.0)分钟")
            return actualWorkoutTime
        }
        
        // 无真实运动数据时，基于步数和活动能量计算
        print("🟡 fetchWorkoutTime: 无真实运动数据，基于步数和活动能量计算")
        return await calculateWorkoutTimeFromActivityData(from: startDate, to: endDate)
    }
    
    /// 获取真实的运动记录数据
    private func fetchActualWorkoutTime(from startDate: Date, to endDate: Date) async -> TimeInterval {
        // 检查权限状态，只有在有权限时才查询
        guard isAuthorized else {
            print("📱 fetchActualWorkoutTime: HealthKit权限未授权，跳过真实数据查询")
            return 0
        }
        
        // 检查运动类型的具体权限
        let workoutAuthStatus = healthStore.authorizationStatus(for: .workoutType())
        guard workoutAuthStatus == .sharingAuthorized else {
            print("📱 fetchActualWorkoutTime: 运动数据权限未授权 (\(workoutAuthStatus.rawValue))，跳过真实数据查询")
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain && nsError.code == 11 {
                        print("📱 fetchActualWorkoutTime: 无运动数据（模拟器常见）")
                    } else if nsError.domain == HKErrorDomain && nsError.code == 5 {
                        print("📱 fetchActualWorkoutTime: 权限问题，使用估算方法")
                    } else {
                        print("🔴 fetchActualWorkoutTime: 查询错误: \(error)")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                // 计算所有运动记录的总时长
                let totalDuration = samples?.compactMap { $0 as? HKWorkout }
                    .reduce(0) { $0 + $1.duration } ?? 0
                
                if totalDuration > 0 {
                    print("✅ fetchActualWorkoutTime: 找到真实运动数据: \(totalDuration/60.0)分钟")
                }
                
                continuation.resume(returning: totalDuration)
            }
            healthStore.execute(query)
        }
    }
    
    /// 基于活动数据计算运动时长
    /// 通过步数和活动能量数据计算相对准确的运动时长
    private func calculateWorkoutTimeFromActivityData(from startDate: Date, to endDate: Date) async -> TimeInterval {
        // 获取步数和活动能量数据
        let steps = await fetchSteps(from: startDate, to: endDate)
        let activeEnergy = await fetchActiveEnergy(from: startDate, to: endDate)
        
        print("🟡 calculateWorkoutTimeFromActivityData: 步数=\(steps), 活动能量=\(activeEnergy)kcal")
        
        // 如果没有任何活动数据，返回0
        if steps == 0 && activeEnergy == 0 {
            print("📱 calculateWorkoutTimeFromActivityData: 无活动数据，返回0")
            return 0
        }
        
        // 基于运动科学的计算方法：
        // 1. 步数转换：平均每分钟100-120步 (中等强度)
        // 2. 卡路里转换：平均每分钟消耗5-8卡路里 (中等强度)
        
        var calculatedTime: TimeInterval = 0
        
        if steps > 0 {
            // 基于步数计算：假设平均每分钟110步
            let timeFromSteps = Double(steps) / 110.0 * 60.0 // 转换为秒
            calculatedTime = max(calculatedTime, timeFromSteps)
            print("🟡 calculateWorkoutTimeFromActivityData: 基于步数计算时长: \(timeFromSteps/60.0)分钟")
        }
        
        if activeEnergy > 0 {
            // 基于活动能量计算：假设平均每分钟消耗6.5卡路里
            let timeFromEnergy = activeEnergy / 6.5 * 60.0 // 转换为秒
            calculatedTime = max(calculatedTime, timeFromEnergy)
            print("🟡 calculateWorkoutTimeFromActivityData: 基于能量计算时长: \(timeFromEnergy/60.0)分钟")
        }
        
        print("✅ calculateWorkoutTimeFromActivityData: 最终计算时长: \(calculatedTime/60.0)分钟")
        return calculatedTime
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
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain && nsError.code == 11 {
                        print("📱 fetchAverageHeartRate: 模拟器无数据（正常情况）")
                    } else {
                        print("🔴 fetchAverageHeartRate: 查询错误: \(error)")
                    }
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
    
    /// 刷新权限状态 - 基于官方文档的方法
    @MainActor
    func refreshAuthorizationStatus() async {
        print("🟡 HealthKitService: 刷新权限状态")
        await checkCurrentAuthorizationStatus()
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
                // 权限状态将通过数据访问验证进行检查
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