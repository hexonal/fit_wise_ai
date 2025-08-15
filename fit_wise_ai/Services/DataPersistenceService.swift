//
//  DataPersistenceService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/14.
//

import Foundation

/**
 * 数据持久化服务
 * 
 * 负责管理应用的本地数据存储，包括：
 * 1. 健康数据历史记录
 * 2. AI建议历史记录
 * 3. 用户偏好设置
 * 4. 数据同步和备份
 */
@MainActor
class DataPersistenceService: ObservableObject {
    /// 文档目录路径
    private let documentsDirectory: URL
    
    init() {
        print("🟢 DataPersistence: 初始化数据持久化服务")
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        setupDataStorage()
        loadRecentData()
        print("🟢 DataPersistence: 数据持久化服务初始化完成")
    }
    
    /// 健康数据历史记录
    @Published var healthDataHistory: [HealthDataRecord] = []
    /// AI建议历史记录
    @Published var adviceHistory: [AIAdviceRecord] = []
    
    /**
     * 设置数据存储
     */
    private func setupDataStorage() {
        // 创建数据目录（如果不存在）
        let dataDirectory = documentsDirectory.appendingPathComponent("FitWiseAI")
        if !FileManager.default.fileExists(atPath: dataDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
                print("🟢 DataPersistence: 创建数据目录成功")
            } catch {
                print("🔴 DataPersistence: 创建数据目录失败: \(error)")
            }
        } else {
            print("🟡 DataPersistence: 数据目录已存在")
        }
    }
    
    /**
     * 保存健康数据记录
     */
    func saveHealthData(_ healthData: HealthData) {
        let record = HealthDataRecord(
            id: UUID(),
            date: healthData.date,
            steps: healthData.steps,
            heartRate: healthData.heartRate,
            activeEnergyBurned: healthData.activeEnergyBurned,
            workoutTime: healthData.workoutTime,
            distanceWalkingRunning: healthData.distanceWalkingRunning,
            savedAt: Date()
        )
        
        // 添加到历史记录
        healthDataHistory.append(record)
        
        // 保持最近30天的数据
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        healthDataHistory = healthDataHistory.filter { $0.date >= thirtyDaysAgo }
        
        // 持久化存储
        saveHealthDataToDisk()
        
        print("健康数据已保存: \(record.date)")
    }
    
    /**
     * 保存AI建议记录
     */
    func saveAIAdvice(_ advice: [AIAdvice]) {
        let records = advice.map { adviceItem in
            AIAdviceRecord(
                id: UUID(),
                title: adviceItem.title,
                content: adviceItem.content,
                category: adviceItem.category.rawValue,
                priority: adviceItem.priority.rawValue,
                createdAt: adviceItem.createdAt,
                savedAt: Date()
            )
        }
        
        // 添加到历史记录
        adviceHistory.append(contentsOf: records)
        
        // 保持最近100条建议
        if adviceHistory.count > 100 {
            adviceHistory = Array(adviceHistory.suffix(100))
        }
        
        // 持久化存储
        saveAdviceHistoryToDisk()
        
        print("AI建议已保存: \(records.count)条")
    }
    
    /**
     * 获取指定日期范围的健康数据
     */
    func getHealthData(from startDate: Date, to endDate: Date) -> [HealthDataRecord] {
        return healthDataHistory.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date < $1.date }
    }
    
    /**
     * 获取指定类别的AI建议历史
     */
    func getAIAdvice(category: AdviceCategory? = nil, limit: Int = 20) -> [AIAdviceRecord] {
        var filtered = adviceHistory
        
        if let category = category {
            filtered = filtered.filter { $0.category == category.rawValue }
        }
        
        return Array(filtered.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    /**
     * 获取健康数据统计
     */
    func getHealthStatistics(days: Int = 7) -> HealthStatistics {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let data = getHealthData(from: startDate, to: Date())
        
        guard !data.isEmpty else {
            return HealthStatistics()
        }
        
        let totalSteps = data.reduce(0) { $0 + $1.steps }
        let totalActiveEnergy = data.reduce(0) { $0 + $1.activeEnergyBurned }
        let totalWorkoutTime = data.reduce(0) { $0 + $1.workoutTime }
        let totalDistance = data.reduce(0) { $0 + $1.distanceWalkingRunning }
        
        let avgHeartRate = data.compactMap { $0.heartRate }.reduce(0, +) / Double(data.compactMap { $0.heartRate }.count)
        
        return HealthStatistics(
            avgStepsPerDay: totalSteps / data.count,
            avgActiveEnergyPerDay: totalActiveEnergy / Double(data.count),
            avgWorkoutTimePerDay: totalWorkoutTime / Double(data.count),
            avgDistancePerDay: totalDistance / Double(data.count),
            avgHeartRate: avgHeartRate.isNaN ? nil : avgHeartRate,
            totalDays: data.count
        )
    }
    
    /**
     * 清理过期数据
     */
    func cleanupOldData() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // 清理过期健康数据
        healthDataHistory = healthDataHistory.filter { $0.date >= thirtyDaysAgo }
        
        // 清理过期AI建议（保留最近100条）
        if adviceHistory.count > 100 {
            adviceHistory = Array(adviceHistory.sorted { $0.createdAt > $1.createdAt }.prefix(100))
        }
        
        // 持久化更新
        saveHealthDataToDisk()
        saveAdviceHistoryToDisk()
        
        print("已清理过期数据")
    }
    
    /**
     * 导出健康数据（用于备份或分享）
     */
    func exportHealthData() -> Data? {
        let exportData = HealthDataExport(
            healthData: healthDataHistory,
            advice: adviceHistory,
            exportDate: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(exportData)
        } catch {
            print("数据导出失败: \(error)")
            return nil
        }
    }
    
    /**
     * 导入健康数据
     */
    func importHealthData(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exportData = try decoder.decode(HealthDataExport.self, from: data)
            
            // 合并导入的数据
            healthDataHistory.append(contentsOf: exportData.healthData)
            adviceHistory.append(contentsOf: exportData.advice)
            
            // 去重和排序
            healthDataHistory = Array(Set(healthDataHistory)).sorted { $0.date < $1.date }
            adviceHistory = Array(Set(adviceHistory)).sorted { $0.createdAt > $1.createdAt }
            
            // 保存更新后的数据
            saveHealthDataToDisk()
            saveAdviceHistoryToDisk()
            
            print("数据导入成功")
            return true
        } catch {
            print("数据导入失败: \(error)")
            return false
        }
    }
    
    // MARK: - 私有方法
    
    /**
     * 加载最近的数据
     */
    private func loadRecentData() {
        loadHealthDataFromDisk()
        loadAdviceHistoryFromDisk()
    }
    
    /**
     * 保存健康数据到磁盘
     */
    private func saveHealthDataToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(healthDataHistory)
            try data.write(to: healthDataURL)
        } catch {
            print("健康数据保存失败: \(error)")
        }
    }
    
    /**
     * 从磁盘加载健康数据
     */
    private func loadHealthDataFromDisk() {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: healthDataURL.path) else {
            print("🟡 DataPersistence: 健康数据文件不存在，使用空数据（首次运行正常）")
            healthDataHistory = []
            return
        }
        
        do {
            let data = try Data(contentsOf: healthDataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            healthDataHistory = try decoder.decode([HealthDataRecord].self, from: data)
            print("🟢 DataPersistence: 健康数据加载成功，共\(healthDataHistory.count)条记录")
        } catch {
            print("🔴 DataPersistence: 健康数据加载失败: \(error)")
            healthDataHistory = []
        }
    }
    
    /**
     * 保存AI建议历史到磁盘
     */
    private func saveAdviceHistoryToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(adviceHistory)
            try data.write(to: adviceHistoryURL)
        } catch {
            print("AI建议历史保存失败: \(error)")
        }
    }
    
    /**
     * 从磁盘加载AI建议历史
     */
    private func loadAdviceHistoryFromDisk() {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: adviceHistoryURL.path) else {
            print("🟡 DataPersistence: AI建议历史文件不存在，使用空数据（首次运行正常）")
            adviceHistory = []
            return
        }
        
        do {
            let data = try Data(contentsOf: adviceHistoryURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            adviceHistory = try decoder.decode([AIAdviceRecord].self, from: data)
            print("🟢 DataPersistence: AI建议历史加载成功，共\(adviceHistory.count)条记录")
        } catch {
            print("🔴 DataPersistence: AI建议历史加载失败: \(error)")
            adviceHistory = []
        }
    }
    
    /**
     * 健康数据文件URL
     */
    private var healthDataURL: URL {
        return documentsDirectory.appendingPathComponent("FitWiseAI/health_data.json")
    }
    
    /**
     * AI建议历史文件URL
     */
    private var adviceHistoryURL: URL {
        return documentsDirectory.appendingPathComponent("FitWiseAI/advice_history.json")
    }
    
}

// MARK: - 数据模型

/**
 * 健康数据记录
 */
struct HealthDataRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let steps: Int
    let heartRate: Double?
    let activeEnergyBurned: Double
    let workoutTime: TimeInterval
    let distanceWalkingRunning: Double
    let savedAt: Date
}

/**
 * AI建议记录
 */
struct AIAdviceRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let content: String
    let category: String
    let priority: String
    let createdAt: Date
    let savedAt: Date
}

/**
 * 健康统计数据
 */
struct HealthStatistics {
    let avgStepsPerDay: Int
    let avgActiveEnergyPerDay: Double
    let avgWorkoutTimePerDay: TimeInterval
    let avgDistancePerDay: Double
    let avgHeartRate: Double?
    let totalDays: Int
    
    init(avgStepsPerDay: Int = 0,
         avgActiveEnergyPerDay: Double = 0,
         avgWorkoutTimePerDay: TimeInterval = 0,
         avgDistancePerDay: Double = 0,
         avgHeartRate: Double? = nil,
         totalDays: Int = 0) {
        self.avgStepsPerDay = avgStepsPerDay
        self.avgActiveEnergyPerDay = avgActiveEnergyPerDay
        self.avgWorkoutTimePerDay = avgWorkoutTimePerDay
        self.avgDistancePerDay = avgDistancePerDay
        self.avgHeartRate = avgHeartRate
        self.totalDays = totalDays
    }
}

/**
 * 健康数据导出格式
 */
struct HealthDataExport: Codable {
    let healthData: [HealthDataRecord]
    let advice: [AIAdviceRecord]
    let exportDate: Date
}