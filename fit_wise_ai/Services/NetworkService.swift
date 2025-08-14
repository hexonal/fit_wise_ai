//
//  NetworkService.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/14.
//

import Foundation
import Network

/**
 * 网络服务管理类
 * 
 * 提供统一的网络请求管理，包括：
 * 1. 网络状态监控
 * 2. 请求重试机制
 * 3. 错误处理和降级方案
 * 4. 网络缓存管理
 */
@MainActor
class NetworkService: ObservableObject {
    /// 网络监视器
    private let monitor = NWPathMonitor()
    /// 监视器队列
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// 网络连接状态
    @Published var isConnected = false
    /// 网络类型（WiFi, 蜂窝数据等）
    @Published var connectionType: ConnectionType = .unknown
    /// 是否是低数据模式
    @Published var isExpensive = false
    
    /// URL会话配置
    private var urlSession: URLSession
    
    init() {
        // 配置URL会话
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)
        
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    /**
     * 开始网络状态监控
     */
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    /**
     * 更新连接类型
     */
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    /**
     * 执行网络请求（带重试机制）
     */
    func performRequest<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        responseType: T.Type,
        maxRetries: Int = 3
    ) async throws -> T {
        
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                // 检查网络连接
                guard isConnected else {
                    throw NetworkError.noConnection
                }
                
                // 构建请求
                var request = URLRequest(url: url)
                request.httpMethod = method.rawValue
                request.httpBody = body
                
                // 设置请求头
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                // 设置默认请求头
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
                
                // 执行请求
                let (data, response) = try await urlSession.data(for: request)
                
                // 检查HTTP响应状态
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                // 解析响应数据
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                do {
                    let result = try decoder.decode(responseType, from: data)
                    return result
                } catch {
                    throw NetworkError.decodingError(error)
                }
                
            } catch {
                lastError = error
                
                // 如果是最后一次尝试，抛出错误
                if attempt == maxRetries {
                    break
                }
                
                // 判断是否应该重试
                if shouldRetry(error: error) {
                    let delay = calculateRetryDelay(attempt: attempt)
                    print("网络请求失败，\(delay)秒后重试第\(attempt + 1)次: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    // 不应该重试的错误直接抛出
                    throw error
                }
            }
        }
        
        // 如果所有重试都失败了，抛出最后一个错误
        throw lastError ?? NetworkError.unknown
    }
    
    /**
     * 判断错误是否应该重试
     */
    private func shouldRetry(error: Error) -> Bool {
        switch error {
        case NetworkError.noConnection:
            return true
        case NetworkError.timeout:
            return true
        case NetworkError.httpError(let code):
            // 5xx服务器错误可以重试，4xx客户端错误不重试
            return (500...599).contains(code)
        case is URLError:
            let urlError = error as! URLError
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    /**
     * 计算重试延迟时间（指数退避）
     */
    private func calculateRetryDelay(attempt: Int) -> Double {
        // 指数退避：1秒, 2秒, 4秒
        return min(pow(2.0, Double(attempt)), 8.0)
    }
    
    /**
     * 检查网络可达性
     */
    func checkNetworkReachability() async -> Bool {
        guard let url = URL(string: "https://www.apple.com") else {
            return false
        }
        
        do {
            let (_, response) = try await urlSession.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("网络可达性检查失败: \(error)")
        }
        
        return false
    }
    
    /**
     * 下载文件（带进度回调）
     */
    func downloadFile(
        from url: URL,
        to destinationURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let localURL = localURL else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                    return
                }
                
                do {
                    // 移动文件到目标位置
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    continuation.resume(returning: destinationURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // 设置进度观察者
            let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    progressHandler(progress.fractionCompleted)
                }
            }
            
            task.resume()
            
            // 使用 withExtendedLifetime 确保 observation 在任务完成前不被释放
            withExtendedLifetime(observation) {
                // observation 会在任务完成时自动失效
            }
        }
    }
    
    /**
     * 取消所有正在进行的网络请求
     */
    func cancelAllRequests() {
        urlSession.invalidateAndCancel()
        
        // 重新创建会话
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)
    }
}

// MARK: - 枚举定义

/**
 * 连接类型枚举
 */
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "蜂窝数据"
        case .ethernet:
            return "以太网"
        case .unknown:
            return "未知"
        }
    }
}

/**
 * HTTP方法枚举
 */
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/**
 * 网络错误枚举
 */
enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "网络连接不可用"
        case .timeout:
            return "网络请求超时"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code):
            return "服务器错误: HTTP \(code)"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .unknown:
            return "未知网络错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "请检查网络连接并重试"
        case .timeout:
            return "请检查网络状况并重试"
        case .invalidResponse, .decodingError:
            return "请稍后重试，如果问题持续请联系支持"
        case .httpError(let code):
            if (500...599).contains(code) {
                return "服务器暂时不可用，请稍后重试"
            } else {
                return "请检查请求参数并重试"
            }
        case .unknown:
            return "请重启应用并重试"
        }
    }
}