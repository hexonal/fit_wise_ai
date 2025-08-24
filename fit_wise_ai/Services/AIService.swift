//
//  AIService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation

/**
 * AI服务类
 * 
 * 专门负责与OpenAI API通信，生成个性化健康建议
 * 采用云端AI方案，提供智能、准确的健康指导
 */
@MainActor
class AIService: ObservableObject {
    // 默认OpenAI API地址
    private let defaultBaseURL = "https://api.openai.com/v1/chat/completions"
    
    private var baseURL: String {
        let savedBaseURL = UserDefaults.standard.string(forKey: "ai_base_url") ?? ""
        if savedBaseURL.isEmpty {
            return defaultBaseURL
        }
        // 确保URL以正确的端点结尾
        if savedBaseURL.hasSuffix("/chat/completions") {
            return savedBaseURL
        } else if savedBaseURL.hasSuffix("/") {
            return savedBaseURL + "chat/completions"
        } else {
            return savedBaseURL + "/chat/completions"
        }
    }
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    /// 获取当前配置的服务提供商信息
    var currentProvider: AIProvider {
        let baseURLString = UserDefaults.standard.string(forKey: "ai_base_url") ?? ""
        return AIProvider.from(baseURL: baseURLString)
    }
    
    /// AI建议结果
    @Published var advice: [AIAdvice] = []
    /// 加载状态
    @Published var isLoading = false
    /// 网络服务实例（延迟初始化以避免主线程隔离问题）
    private lazy var networkService: NetworkService = {
        MainActor.assumeIsolated {
            NetworkService()
        }
    }()
    
    /**
     * 生成AI建议的主要方法
     * 
     * 使用OpenAI API分析健康数据，生成个性化建议
     * 如果API不可用，使用本地规则作为降级方案
     */
    func generateAdvice(from healthData: HealthData) async {
        isLoading = true
        
        var generatedAdvice: [AIAdvice] = []
        
        // 检查网络连接状态
        guard networkService.isConnected else {
            print("网络不可用，使用离线建议")
            generatedAdvice = generateOfflineAdvice(from: healthData)
            updateAdvice(generatedAdvice)
            return
        }
        
        // 检查API密钥配置
        guard !apiKey.isEmpty else {
            print("API密钥未配置，使用默认建议")
            generatedAdvice = generateDefaultAdvice(from: healthData)
            updateAdvice(generatedAdvice)
            return
        }
        
        // 调用OpenAI API生成智能建议
        do {
            let prompt = createPrompt(from: healthData)
            generatedAdvice = try await callOpenAIAPI(prompt: prompt)
            print("OpenAI API调用成功")
        } catch {
            print("OpenAI API调用失败: \(error)")
            // 降级到离线建议
            generatedAdvice = generateOfflineAdvice(from: healthData)
        }
        
        updateAdvice(generatedAdvice)
    }
    
    /**
     * 更新建议并结束加载状态
     */
    private func updateAdvice(_ advice: [AIAdvice]) {
        self.advice = advice
        self.isLoading = false
    }
    
    /**
     * 生成基于7天数据的AI建议
     */
    func generateWeeklyAdvice(from weeklyData: [HealthData]) async {
        isLoading = true
        
        var generatedAdvice: [AIAdvice] = []
        
        // 检查网络连接状态
        guard networkService.isConnected else {
            print("网络不可用，使用离线建议")
            generatedAdvice = generateWeeklyOfflineAdvice(from: weeklyData)
            updateAdvice(generatedAdvice)
            return
        }
        
        // 检查API密钥配置
        guard !apiKey.isEmpty else {
            print("API密钥未配置，使用默认建议")
            generatedAdvice = generateWeeklyOfflineAdvice(from: weeklyData)
            updateAdvice(generatedAdvice)
            return
        }
        
        // 调用OpenAI API生成智能建议
        do {
            let prompt = createWeeklyPrompt(from: weeklyData)
            generatedAdvice = try await callOpenAIAPI(prompt: prompt)
            print("OpenAI API调用成功")
        } catch {
            print("OpenAI API调用失败: \(error)")
            // 降级到离线建议
            generatedAdvice = generateWeeklyOfflineAdvice(from: weeklyData)
        }
        
        updateAdvice(generatedAdvice)
    }
    
    private func createPrompt(from healthData: HealthData) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return """
        请根据以下健康数据为用户提供个性化的健身建议：
        
        日期: \(formatter.string(from: healthData.date))
        步数: \(healthData.steps) 步
        心率: \(healthData.heartRate.map { String(format: "%.0f", $0) } ?? "未测量") bpm
        活动消耗: \(String(format: "%.0f", healthData.activeEnergyBurned)) 卡路里
        运动时长: \(String(format: "%.0f", healthData.workoutTime / 60)) 分钟
        步行/跑步距离: \(String(format: "%.1f", healthData.distanceWalkingRunning / 1000)) 公里
        
        请提供3-4条简洁实用的建议，分别涵盖：
        1. 运动建议（根据当天活动量）
        2. 休息建议（根据运动强度）
        3. 营养建议（根据消耗情况）
        
        每条建议请用中文回复，控制在30字以内，要具体可执行。
        请以JSON格式返回，包含title和content字段。
        """
    }
    
    private func createWeeklyPrompt(from weeklyData: [HealthData]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        
        // 计算7天数据统计
        let totalSteps = weeklyData.reduce(0) { $0 + $1.steps }
        let avgSteps = totalSteps / max(weeklyData.count, 1)
        let totalCalories = weeklyData.reduce(0) { $0 + $1.activeEnergyBurned }
        let avgCalories = totalCalories / Double(max(weeklyData.count, 1))
        let totalWorkoutMinutes = weeklyData.reduce(0) { $0 + $1.workoutTime } / 60
        let avgWorkoutMinutes = totalWorkoutMinutes / Double(max(weeklyData.count, 1))
        
        // 找出最高和最低值
        let maxSteps = weeklyData.map { $0.steps }.max() ?? 0
        let minSteps = weeklyData.map { $0.steps }.min() ?? 0
        
        var dataDetails = "近7天健康数据详情：\n"
        for data in weeklyData.suffix(7) {
            dataDetails += """
            \(formatter.string(from: data.date)): 
            步数\(data.steps)步, 
            消耗\(String(format: "%.0f", data.activeEnergyBurned))卡, 
            运动\(String(format: "%.0f", data.workoutTime / 60))分钟\n
            """
        }
        
        return """
        请根据用户近7天的健康数据趋势，提供个性化的健康建议：
        
        【7天数据统计】
        平均步数: \(avgSteps) 步/天
        最高步数: \(maxSteps) 步
        最低步数: \(minSteps) 步
        总消耗: \(String(format: "%.0f", totalCalories)) 卡路里
        平均消耗: \(String(format: "%.0f", avgCalories)) 卡路里/天
        总运动时长: \(String(format: "%.0f", totalWorkoutMinutes)) 分钟
        平均运动: \(String(format: "%.0f", avgWorkoutMinutes)) 分钟/天
        
        \(dataDetails)
        
        请基于数据趋势提供4-5条建议：
        1. 运动趋势分析和改进建议
        2. 活动规律性评估
        3. 恢复和休息建议
        4. 营养补充建议
        5. 下周目标设定
        
        每条建议请用中文回复，控制在40字以内，要基于数据分析，具体可执行。
        """
    }
    
    /**
     * 调用OpenAI API生成建议
     */
    private func callOpenAIAPI(prompt: String) async throws -> [AIAdvice] {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 构建请求体
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "system", content: "你是一位专业的健康顾问，根据用户的健康数据提供简洁实用的建议。"),
                OpenAIMessage(role: "user", content: prompt)
            ],
            max_tokens: 800,
            temperature: 0.7
        )
        
        // 根据不同的API提供商设置请求头
        var headers = ["Content-Type": "application/json"]
        
        // 根据baseURL判断API提供商类型并设置相应的认证头
        if baseURL.contains("api.anthropic.com") {
            headers["x-api-key"] = apiKey
            headers["anthropic-version"] = "2023-06-01"
        } else {
            // OpenAI兼容格式
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        
        // 使用网络服务进行API调用，获得重试和错误处理能力
        let response: OpenAIResponse = try await networkService.performRequest(
            url: url,
            method: .POST,
            headers: headers,
            body: try JSONEncoder().encode(requestBody),
            responseType: OpenAIResponse.self,
            maxRetries: 2
        )
        
        // 解析响应
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No Response"])
        }
        
        return parseAIResponse(content)
    }
    
    private func parseAIResponse(_ content: String) -> [AIAdvice] {
        // 简单的解析逻辑，实际项目中需要更robust的JSON解析
        var advice: [AIAdvice] = []
        
        // 如果API返回格式不符合预期，使用默认建议
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let category: AdviceCategory
                switch index % 3 {
                case 0: category = .exercise
                case 1: category = .rest
                default: category = .nutrition
                }
                
                advice.append(AIAdvice(
                    title: category.rawValue,
                    content: line.trimmingCharacters(in: .whitespaces),
                    category: category
                ))
            }
        }
        
        return advice.isEmpty ? generateDefaultAdvice() : advice
    }
    
    /**
     * 生成离线智能建议
     * 
     * 基于健康数据分析，提供个性化的离线建议
     * 这是网络不可用时的高质量降级方案
     */
    private func generateOfflineAdvice(from healthData: HealthData) -> [AIAdvice] {
        var advice: [AIAdvice] = []
        
        // 生成运动建议
        advice.append(generateExerciseAdvice(from: healthData))
        
        // 生成营养建议
        advice.append(generateNutritionAdvice(from: healthData))
        
        // 生成休息建议
        advice.append(generateRestAdvice(from: healthData))
        
        return advice
    }
    
    /**
     * 生成默认建议（完全降级方案）
     */
    private func generateDefaultAdvice(from healthData: HealthData? = nil) -> [AIAdvice] {
        var advice: [AIAdvice] = []
        
        // 基于健康数据生成简单的建议逻辑
        if let data = healthData {
            if data.steps < 5000 {
                advice.append(AIAdvice(
                    title: "步数建议",
                    content: "今天步数较少，建议增加30分钟散步",
                    category: .exercise,
                    priority: .medium
                ))
            } else if data.steps > 10000 {
                advice.append(AIAdvice(
                    title: "运动表现",
                    content: "今天步数达标，保持良好的运动习惯！",
                    category: .exercise,
                    priority: .low
                ))
            }
            
            if data.activeEnergyBurned < 200 {
                advice.append(AIAdvice(
                    title: "活动建议",
                    content: "今天活动消耗较低，尝试一些有氧运动",
                    category: .exercise,
                    priority: .high
                ))
            }
            
            advice.append(AIAdvice(
                title: "营养补充",
                content: "记得及时补充水分，保持身体水分平衡",
                category: .nutrition,
                priority: .medium
            ))
            
            advice.append(AIAdvice(
                title: "休息提醒",
                content: "运动后适当休息，保证充足的睡眠时间",
                category: .rest,
                priority: .medium
            ))
        } else {
            advice = [
                AIAdvice(title: "每日运动", content: "保持每天至少30分钟的有氧运动", category: .exercise),
                AIAdvice(title: "合理饮食", content: "均衡膳食，多吃蔬菜水果", category: .nutrition),
                AIAdvice(title: "充足睡眠", content: "每晚保证7-8小时的优质睡眠", category: .rest)
            ]
        }
        
        return advice
    }
    
    // MARK: - 智能离线建议生成
    
    /**
     * 生成运动建议
     */
    private func generateExerciseAdvice(from healthData: HealthData) -> AIAdvice {
        let steps = healthData.steps
        let activeEnergy = healthData.activeEnergyBurned
        let workoutTime = healthData.workoutTime
        
        var title = "运动建议"
        var content = ""
        var priority: AdvicePriority = .medium
        
        // 基于步数分析
        if steps < 3000 {
            content = "今日步数较少，建议增加30-45分钟户外散步"
            priority = .high
            title = "增加日常活动"
        } else if steps < 6000 {
            content = "步数偏低，建议进行20分钟快走或轻度运动"
            priority = .medium
            title = "提升活动量"
        } else if steps < 10000 {
            content = "步数接近目标，再坚持15分钟运动就更完美了"
            priority = .medium
            title = "坚持运动"
        } else if steps > 15000 {
            content = "运动量充足！明天可以尝试力量训练或拉伸"
            priority = .low
            title = "运动表现优秀"
        } else {
            content = "运动量达标，保持当前节奏，注意运动后恢复"
            priority = .low
            title = "运动状态良好"
        }
        
        // 基于活动消耗调整
        if activeEnergy < 150 && steps > 8000 {
            content += "，可以增加运动强度"
        } else if activeEnergy > 400 {
            content += "，注意适当休息"
        }
        
        return AIAdvice(
            title: title,
            content: content,
            category: .exercise,
            priority: priority
        )
    }
    
    /**
     * 生成营养建议
     */
    private func generateNutritionAdvice(from healthData: HealthData) -> AIAdvice {
        let activeEnergy = healthData.activeEnergyBurned
        let steps = healthData.steps
        let workoutTime = healthData.workoutTime
        
        var title = "营养建议"
        var content = ""
        var priority: AdvicePriority = .medium
        
        // 基于活动量分析营养需求
        if activeEnergy < 200 && steps < 5000 {
            content = "今日活动量较低，建议清淡饮食，多吃蔬菜水果"
            title = "清淡饮食"
            priority = .medium
        } else if activeEnergy > 400 || workoutTime > 1800 {
            content = "运动消耗较大，及时补充蛋白质和优质碳水化合物"
            title = "运动营养补充"
            priority = .high
        } else {
            content = "保持均衡饮食，适量蛋白质，充足水分补充"
            title = "营养均衡"
            priority = .medium
        }
        
        // 水分补充提醒
        if workoutTime > 1200 || activeEnergy > 300 {
            content += "，多喝水保持水分平衡"
        }
        
        // 时间段建议
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 10 {
            content += "，早餐要吃好"
        } else if hour > 18 {
            content += "，晚餐要清淡"
        }
        
        return AIAdvice(
            title: title,
            content: content,
            category: .nutrition,
            priority: priority
        )
    }
    
    /**
     * 生成休息建议
     */
    private func generateRestAdvice(from healthData: HealthData) -> AIAdvice {
        let heartRate = healthData.heartRate
        let workoutTime = healthData.workoutTime
        let activeEnergy = healthData.activeEnergyBurned
        let steps = healthData.steps
        
        var title = "休息建议"
        var content = ""
        var priority: AdvicePriority = .medium
        
        // 基于心率分析
        if let hr = heartRate {
            if hr > 100 {
                content = "心率较高，建议深呼吸放松，确保充足睡眠"
                title = "放松休息"
                priority = .high
            } else if hr < 60 {
                content = "心率正常，保持规律作息，适当轻度运动"
                title = "规律作息"
                priority = .medium
            }
        }
        
        // 基于运动强度分析
        if workoutTime > 2400 || activeEnergy > 500 {
            content = "今日运动强度较大，记得做拉伸放松，早点休息"
            title = "运动后恢复"
            priority = .high
        } else if workoutTime < 600 && activeEnergy < 150 {
            content = "今日活动量适中，睡前可做轻度拉伸，保证睡眠质量"
            title = "优质睡眠"
            priority = .medium
        }
        
        // 默认情况
        if content.isEmpty {
            content = "保持规律作息，睡前避免剧烈运动，确保7-8小时睡眠"
            title = "作息调节"
            priority = .medium
        }
        
        // 时间段提醒
        let hour = Calendar.current.component(.hour, from: Date())
        if hour > 21 {
            content += "，现在是休息时间，准备睡觉吧"
            priority = .high
        } else if hour > 18 {
            content += "，晚上可以做些放松活动"
        }
        
        return AIAdvice(
            title: title,
            content: content,
            category: .rest,
            priority: priority
        )
    }
    
    /**
     * 生成基于7天数据的离线建议
     */
    private func generateWeeklyOfflineAdvice(from weeklyData: [HealthData]) -> [AIAdvice] {
        guard !weeklyData.isEmpty else {
            return generateDefaultAdvice()
        }
        
        var advice: [AIAdvice] = []
        
        // 计算7天统计数据
        let totalSteps = weeklyData.reduce(0) { $0 + $1.steps }
        let avgSteps = totalSteps / weeklyData.count
        let totalCalories = weeklyData.reduce(0) { $0 + $1.activeEnergyBurned }
        let avgCalories = totalCalories / Double(weeklyData.count)
        let totalWorkoutMinutes = weeklyData.reduce(0) { $0 + $1.workoutTime } / 60
        
        // 运动趋势建议
        if avgSteps < 5000 {
            advice.append(AIAdvice(
                title: "提升日常活动",
                content: "近7天平均步数偏低，建议每天增加30分钟快走",
                category: .exercise,
                priority: .high
            ))
        } else if avgSteps > 10000 {
            advice.append(AIAdvice(
                title: "保持优秀表现",
                content: "运动量充足！可尝试增加力量训练或瑜伽",
                category: .exercise,
                priority: .low
            ))
        } else {
            advice.append(AIAdvice(
                title: "稳步提升",
                content: "运动量适中，建议每天增加1000步挑战自己",
                category: .exercise,
                priority: .medium
            ))
        }
        
        // 活动规律性评估
        let stepVariance = calculateVariance(weeklyData.map { $0.steps })
        if stepVariance > 3000 {
            advice.append(AIAdvice(
                title: "保持规律运动",
                content: "运动量波动较大，建议制定固定运动时间",
                category: .general,
                priority: .medium
            ))
        }
        
        // 营养建议
        if avgCalories > 400 {
            advice.append(AIAdvice(
                title: "营养补充",
                content: "运动消耗较大，注意补充蛋白质和电解质",
                category: .nutrition,
                priority: .high
            ))
        } else {
            advice.append(AIAdvice(
                title: "均衡饮食",
                content: "保持清淡饮食，多吃蔬菜水果补充维生素",
                category: .nutrition,
                priority: .medium
            ))
        }
        
        // 休息建议
        if totalWorkoutMinutes > 420 { // 7小时以上
            advice.append(AIAdvice(
                title: "充分休息",
                content: "本周运动量较大，确保充足睡眠和拉伸放松",
                category: .rest,
                priority: .high
            ))
        }
        
        return advice
    }
    
    private func calculateVariance(_ values: [Int]) -> Double {
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let variance = values.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

// MARK: - API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
    let temperature: Double
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Error Types
// 使用EventDrivenAIService中定义的AIServiceError

// MARK: - AI Provider Types
struct AIProvider {
    let name: String
    let baseURL: String
    let isCustom: Bool
    
    static let openAI = AIProvider(name: "OpenAI", baseURL: "https://api.openai.com/v1", isCustom: false)
    static let anthropic = AIProvider(name: "Anthropic Claude", baseURL: "https://api.anthropic.com/v1", isCustom: false)
    static let deepseek = AIProvider(name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", isCustom: false)
    static let moonshot = AIProvider(name: "Moonshot AI", baseURL: "https://api.moonshot.cn/v1", isCustom: false)
    static let custom = AIProvider(name: "自定义", baseURL: "", isCustom: true)
    
    static let allProviders: [AIProvider] = [.openAI, .anthropic, .deepseek, .moonshot, .custom]
    
    static func from(baseURL: String) -> AIProvider {
        if baseURL.isEmpty {
            return .openAI
        }
        
        for provider in allProviders where !provider.isCustom {
            if baseURL.contains(provider.baseURL.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/v1", with: "")) {
                return provider
            }
        }
        
        return AIProvider(name: "自定义", baseURL: baseURL, isCustom: true)
    }
}