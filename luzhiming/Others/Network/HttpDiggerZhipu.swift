
import Foundation
import Alamofire

/// 智谱 AI 网络层封装（Alamofire）
/// 目前实现：语音转文本（GLM ASR）
class HttpDiggerZhipu {
    // 文档：https://docs.bigmodel.cn/api-reference/模型-api/语音转文本
    // 接口：POST https://open.bigmodel.cn/api/paas/v4/audio/transcriptions

    private let baseURLString = "https://open.bigmodel.cn/api"

    // MARK: - Singleton
    static let shared = HttpDiggerZhipu()
    private init() {}

    // 从本地存储获取 API Key
    private func resolvedAPIKey() -> String? {
        // 优先从本地文件读取
        if let key = LocalKeysTool.shared.getZhipuAPIKey(), !key.isEmpty {
            return key
        }
        // 其次尝试从环境变量读取 ZHIPU_API_KEY
        if let env = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"], !env.isEmpty {
            return env
        }
        return nil
    }

    // MARK: - Models
    struct TranscriptionSegment: Codable {
        let id: Int?
        let start: Double?
        let end: Double?
        let text: String?
    }

    struct TranscriptionResponse: Codable {
        let id: String?
        let created: Int?
        let request_id: String?
        let model: String?
        let segments: [TranscriptionSegment]?
        let text: String?
    }

    enum ZhipuError: Error, LocalizedError {
        case missingAPIKey
        case fileNotFound
        case fileTooLarge
        case requestFailed(underlying: Error)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "缺少 ZHIPU_API_KEY，请先调用 configure(apiKey:) 或设置环境变量 ZHIPU_API_KEY"
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

    // MARK: - API: 语音转文本（同步）
    /// 调用智谱 ASR 将音频转文本
    /// - Parameters:
    ///   - fileURL: 音频文件本地路径（官方建议 wav/mp3；其他格式可能失败）
    ///   - model: 模型编码，默认 glm-asr
    ///   - temperature: 0.0~1.0，可不传
    ///   - stream: 同步场景请传 false 或不传
    ///   - requestId: 可选请求 ID
    ///   - userId: 可选用户 ID
    ///   - completion: 结果回调
    func transcribe(
        fileURL: URL,
        model: String = "glm-asr",
        temperature: Double? = nil,
        stream: Bool? = nil,
        requestId: String? = nil,
        userId: String? = nil,
        completion: @escaping (Result<TranscriptionResponse, Error>) -> Void
    ) {
        guard let apiKey = resolvedAPIKey() else {
            completion(.failure(ZhipuError.missingAPIKey)); return
        }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.failure(ZhipuError.fileNotFound)); return
        }

        // 文件大小限制：<= 25MB（文档要求）
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? NSNumber, size.intValue > 25 * 1024 * 1024 {
            completion(.failure(ZhipuError.fileTooLarge)); return
        }

        // 非 wav/mp3 的情况：给出提示，但仍然尝试上传（某些情况下服务端可能支持更多格式）
        let lowerExt = fileURL.pathExtension.lowercased()
        if lowerExt != "wav" && lowerExt != "mp3" {
            print("⚠️ 提示：当前上传文件扩展名为 .\(lowerExt)，官方文档推荐 wav/mp3，其他格式可能会失败。")
        }

        let url = baseURLString + "/paas/v4/audio/transcriptions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]

        AF.upload(multipartFormData: { form in
            // 模型
            if let data = model.data(using: .utf8) {
                form.append(data, withName: "model")
            }
            // 可选参数
            if let t = temperature { form.append("\(t)".data(using: .utf8)!, withName: "temperature") }
            // 始终附带 stream 字段，默认 false（同步返回）
            let streamValue = (stream != nil) ? "\(stream!)" : "false"
            form.append(streamValue.data(using: .utf8)!, withName: "stream")
            if let rid = requestId { form.append(rid.data(using: .utf8)!, withName: "request_id") }
            if let uid = userId { form.append(uid.data(using: .utf8)!, withName: "user_id") }

            // 音频文件
            form.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: self.mimeType(for: lowerExt))
        }, to: url, method: .post, headers: headers)
        .responseData { response in
            // Debug 输出：便于查看服务端返回的详细错误信息
            #if DEBUG
            if let req = response.request {
                print("[ZHIPU] Request: \(req.httpMethod ?? "?") \(req.url?.absoluteString ?? "?")")
            }
            if let code = response.response?.statusCode {
                print("[ZHIPU] Status: \(code)")
            }
            if let body = response.data.flatMap({ String(data: $0, encoding: .utf8) }) {
                print("[ZHIPU] Body: \(body)")
            }
            #endif

            if let status = response.response?.statusCode, !(200..<300).contains(status) {
                let body = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
                let err = NSError(domain: "Zhipu", code: status, userInfo: [NSLocalizedDescriptionKey: "Status \(status). Body: \(body)"])
                completion(.failure(ZhipuError.requestFailed(underlying: err)))
                return
            }

            guard let data = response.data else {
                completion(.failure(ZhipuError.invalidResponse)); return
            }

            do {
                let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(ZhipuError.requestFailed(underlying: error)))
            }
        }
    }

    // 简单的 mimeType 推断
    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "wav": return "audio/wav"
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        default: return "application/octet-stream"
        }
    }
}
