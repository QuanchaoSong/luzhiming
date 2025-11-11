import Foundation
import Alamofire

/// OpenAI 语音转文本封装（Alamofire）
/// 文档：https://platform.openai.com/docs/guides/speech-to-text
/// 接口：POST https://api.openai.com/v1/audio/transcriptions
class HttpDiggerOpenAI {
    
    private let baseURLString = "https://api.openai.com/v1"
    
    // MARK: - Singleton
    static let shared = HttpDiggerOpenAI()
    private init() {}
    
    // 从本地存储获取 API Key
    private func resolvedAPIKey() -> String? {
        // 优先从本地文件读取
        if let key = LocalKeysTool.shared.getOpenAIAPIKey(), !key.isEmpty {
            return key
        }
        // 其次尝试从环境变量读取 OPENAI_API_KEY
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        return nil
    }
    
    // MARK: - Models
    
    /// 转录结果
    struct TranscriptionResponse: Codable {
        let text: String?
        
        // verbose_json 格式的额外字段
        let task: String?
        let language: String?
        let duration: Double?
        let segments: [TranscriptionSegment]?
        let words: [TranscriptionWord]?
    }
    
    /// 转录片段（verbose_json 格式）
    struct TranscriptionSegment: Codable {
        let id: Int?
        let seek: Int?
        let start: Double?
        let end: Double?
        let text: String?
        let tokens: [Int]?
        let temperature: Double?
        let avg_logprob: Double?
        let compression_ratio: Double?
        let no_speech_prob: Double?
    }
    
    /// 转录词汇（timestamp_granularities=["word"] 时）
    struct TranscriptionWord: Codable {
        let word: String?
        let start: Double?
        let end: Double?
    }
    
    /// OpenAI 错误
    enum OpenAIError: Error, LocalizedError {
        case missingAPIKey
        case fileNotFound
        case fileTooLarge
        case requestFailed(underlying: Error)
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "缺少 OPENAI_API_KEY，请在设置中配置或设置环境变量"
            case .fileNotFound:
                return "音频文件不存在"
            case .fileTooLarge:
                return "音频文件超过 25MB 限制"
            case .requestFailed(let underlying):
                return "网络请求失败：\(underlying.localizedDescription)"
            case .invalidResponse:
                return "返回数据解析失败"
            }
        }
    }
    
    // MARK: - API: 语音转文本
    
    /// 调用 OpenAI Whisper API 将音频转文本
    /// - Parameters:
    ///   - fileURL: 音频文件本地路径（支持 mp3, mp4, mpeg, mpga, m4a, wav, webm）
    ///   - model: 模型名称，默认 "whisper-1"
    ///            可选: "whisper-1", "gpt-4o-transcribe", "gpt-4o-mini-transcribe"
    ///   - language: 可选语言代码（如 "zh", "en"），帮助提高准确性
    ///   - prompt: 可选提示文本，用于改进转录质量
    ///   - responseFormat: 响应格式，默认 "json"
    ///                    可选: "json", "text", "srt", "verbose_json", "vtt"
    ///   - temperature: 采样温度 0.0~1.0，默认 0
    ///   - timestampGranularities: 时间戳粒度（仅 whisper-1 支持）
    ///                            可选: ["segment"], ["word"], ["segment", "word"]
    ///   - completion: 结果回调
    func transcribe(
        fileURL: URL,
        model: String = "whisper-1",
        language: String? = nil,
        prompt: String? = nil,
        responseFormat: String = "json",
        temperature: Double = 0.0,
        timestampGranularities: [String]? = nil,
        completion: @escaping (Result<TranscriptionResponse, Error>) -> Void
    ) {
        guard let apiKey = resolvedAPIKey() else {
            completion(.failure(OpenAIError.missingAPIKey))
            return
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.failure(OpenAIError.fileNotFound))
            return
        }
        
        // 文件大小限制：<= 25MB
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? NSNumber,
           size.intValue > 25 * 1024 * 1024 {
            completion(.failure(OpenAIError.fileTooLarge))
            return
        }
        
        let url = baseURLString + "/audio/transcriptions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]
        
        AF.upload(multipartFormData: { form in
            // 必需参数：文件
            form.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: self.mimeType(for: fileURL.pathExtension))
            
            // 必需参数：模型
            if let modelData = model.data(using: .utf8) {
                form.append(modelData, withName: "model")
            }
            
            // 可选参数
            if let lang = language, let langData = lang.data(using: .utf8) {
                form.append(langData, withName: "language")
            }
            
            if let p = prompt, let pData = p.data(using: .utf8) {
                form.append(pData, withName: "prompt")
            }
            
            if let formatData = responseFormat.data(using: .utf8) {
                form.append(formatData, withName: "response_format")
            }
            
            if let tempData = "\(temperature)".data(using: .utf8) {
                form.append(tempData, withName: "temperature")
            }
            
            // timestamp_granularities（仅 whisper-1 支持）
            if let granularities = timestampGranularities, !granularities.isEmpty {
                for granularity in granularities {
                    if let data = granularity.data(using: .utf8) {
                        form.append(data, withName: "timestamp_granularities[]")
                    }
                }
            }
        }, to: url, method: .post, headers: headers)
        .responseData { response in
            // Debug 输出
            #if DEBUG
            if let req = response.request {
                print("[OPENAI] Request: \(req.httpMethod ?? "?") \(req.url?.absoluteString ?? "?")")
            }
            if let code = response.response?.statusCode {
                print("[OPENAI] Status: \(code)")
            }
            if let body = response.data.flatMap({ String(data: $0, encoding: .utf8) }) {
                print("[OPENAI] Body: \(body)")
            }
            #endif
            
            // 检查 HTTP 状态码
            if let status = response.response?.statusCode, !(200..<300).contains(status) {
                let body = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
                let err = NSError(
                    domain: "OpenAI",
                    code: status,
                    userInfo: [NSLocalizedDescriptionKey: "Status \(status). Body: \(body)"]
                )
                completion(.failure(OpenAIError.requestFailed(underlying: err)))
                return
            }
            
            guard let data = response.data else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            // 如果 response_format 是 "text"，直接返回纯文本
            if responseFormat == "text" {
                if let text = String(data: data, encoding: .utf8) {
                    let result = TranscriptionResponse(
                        text: text,
                        task: nil,
                        language: nil,
                        duration: nil,
                        segments: nil,
                        words: nil
                    )
                    completion(.success(result))
                } else {
                    completion(.failure(OpenAIError.invalidResponse))
                }
                return
            }
            
            // 其他格式（json, verbose_json）解析为 JSON
            do {
                let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(OpenAIError.requestFailed(underlying: error)))
            }
        }
    }
    
    // MARK: - 翻译 API（将音频翻译成英文）
    
    /// 调用 OpenAI Translations API 将音频翻译成英文
    /// - Parameters:
    ///   - fileURL: 音频文件本地路径
    ///   - model: 模型名称，默认 "whisper-1"（仅支持 whisper-1）
    ///   - prompt: 可选提示文本
    ///   - responseFormat: 响应格式，默认 "json"
    ///   - temperature: 采样温度 0.0~1.0，默认 0
    ///   - completion: 结果回调
    func translate(
        fileURL: URL,
        model: String = "whisper-1",
        prompt: String? = nil,
        responseFormat: String = "json",
        temperature: Double = 0.0,
        completion: @escaping (Result<TranscriptionResponse, Error>) -> Void
    ) {
        guard let apiKey = resolvedAPIKey() else {
            completion(.failure(OpenAIError.missingAPIKey))
            return
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.failure(OpenAIError.fileNotFound))
            return
        }
        
        // 文件大小限制：<= 25MB
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? NSNumber,
           size.intValue > 25 * 1024 * 1024 {
            completion(.failure(OpenAIError.fileTooLarge))
            return
        }
        
        let url = baseURLString + "/audio/translations"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]
        
        AF.upload(multipartFormData: { form in
            // 必需参数
            form.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: self.mimeType(for: fileURL.pathExtension))
            
            if let modelData = model.data(using: .utf8) {
                form.append(modelData, withName: "model")
            }
            
            // 可选参数
            if let p = prompt, let pData = p.data(using: .utf8) {
                form.append(pData, withName: "prompt")
            }
            
            if let formatData = responseFormat.data(using: .utf8) {
                form.append(formatData, withName: "response_format")
            }
            
            if let tempData = "\(temperature)".data(using: .utf8) {
                form.append(tempData, withName: "temperature")
            }
        }, to: url, method: .post, headers: headers)
        .responseData { response in
            // Debug 输出
            #if DEBUG
            if let req = response.request {
                print("[OPENAI TRANSLATE] Request: \(req.httpMethod ?? "?") \(req.url?.absoluteString ?? "?")")
            }
            if let code = response.response?.statusCode {
                print("[OPENAI TRANSLATE] Status: \(code)")
            }
            if let body = response.data.flatMap({ String(data: $0, encoding: .utf8) }) {
                print("[OPENAI TRANSLATE] Body: \(body)")
            }
            #endif
            
            if let status = response.response?.statusCode, !(200..<300).contains(status) {
                let body = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
                let err = NSError(
                    domain: "OpenAI",
                    code: status,
                    userInfo: [NSLocalizedDescriptionKey: "Status \(status). Body: \(body)"]
                )
                completion(.failure(OpenAIError.requestFailed(underlying: err)))
                return
            }
            
            guard let data = response.data else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            if responseFormat == "text" {
                if let text = String(data: data, encoding: .utf8) {
                    let result = TranscriptionResponse(
                        text: text,
                        task: nil,
                        language: nil,
                        duration: nil,
                        segments: nil,
                        words: nil
                    )
                    completion(.success(result))
                } else {
                    completion(.failure(OpenAIError.invalidResponse))
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(OpenAIError.requestFailed(underlying: error)))
            }
        }
    }
    
    // MARK: - Helper
    
    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "mp3": return "audio/mpeg"
        case "mp4", "m4a": return "audio/mp4"
        case "mpeg", "mpga": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "webm": return "audio/webm"
        default: return "application/octet-stream"
        }
    }
}
