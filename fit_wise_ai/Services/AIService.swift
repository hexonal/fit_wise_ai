//
//  AIService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import Foundation

class AIService: ObservableObject {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    @Published var advice: [AIAdvice] = []
    @Published var isLoading = false
    
    func generateAdvice(from healthData: HealthData) async {
        await MainActor.run {
            isLoading = true
        }
        
        // 检查API密钥是否配置
        guard !apiKey.isEmpty else {
            await MainActor.run {
                self.advice = generateDefaultAdvice(from: healthData)
                self.isLoading = false
            }
            return
        }
        
        let prompt = createPrompt(from: healthData)
        
        do {
            let advice = try await callOpenAIAPI(prompt: prompt)
            await MainActor.run {
                self.advice = advice
                self.isLoading = false
            }
        } catch {
            print("AI建议生成失败: \(error)")
            await MainActor.run {
                // 提供默认建议以防API调用失败
                self.advice = generateDefaultAdvice(from: healthData)
                self.isLoading = false
            }
        }
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
    
    private func callOpenAIAPI(prompt: String) async throws -> [AIAdvice] {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            max_tokens: 500,
            temperature: 0.7
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return parseAIResponse(response.choices.first?.message.content ?? "")
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
enum AIServiceError: Error {
    case invalidURL
    case noResponse
    case decodingError
}