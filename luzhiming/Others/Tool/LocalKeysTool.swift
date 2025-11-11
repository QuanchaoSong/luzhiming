import Foundation

/// 本地 API Key 管理工具
/// 从 ~/.luzhiming/key_files/ 目录读取存储的 API Keys
class LocalKeysTool {
    static let shared = LocalKeysTool()
    
    private init() {}
    
    // MARK: - Paths
    private var keyFilesDirectory: URL {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let luzimingDir = homeDir.appendingPathComponent(".luzhiming")
        let keyFilesDir = luzimingDir.appendingPathComponent("key_files")
        return keyFilesDir
    }
    
    // MARK: - Public Methods
    /// 获取智谱 API Key
    func getZhipuAPIKey() -> String? {
        return loadKeyFromFile(filename: "zhipu_api_key")
    }
    
    /// 保存智谱 API Key
    func saveZhipuAPIKey(_ key: String) -> Bool {
        return saveKeyToFile(key, filename: "zhipu_api_key")
    }
    
    /// 获取 OpenAI API Key
    func getOpenAIAPIKey() -> String? {
        return loadKeyFromFile(filename: "openai_api_key")
    }
    
    /// 保存 OpenAI API Key
    func saveOpenAIAPIKey(_ key: String) -> Bool {
        return saveKeyToFile(key, filename: "openai_api_key")
    }
    
    /// 获取豆包 API Key
    func getDoubaoAPIKey() -> String? {
        return loadKeyFromFile(filename: "doubao_api_key")
    }
    
    /// 保存豆包 API Key
    func saveDoubaoAPIKey(_ key: String) -> Bool {
        return saveKeyToFile(key, filename: "doubao_api_key")
    }
    
    // MARK: - Private Methods
    private func loadKeyFromFile(filename: String) -> String? {
        let fileURL = keyFilesDirectory.appendingPathComponent(filename)
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            print("Error loading key from \(filename): \(error)")
            return nil
        }
    }
    
    private func saveKeyToFile(_ key: String, filename: String) -> Bool {
        // 确保目录存在
        let fileManager = FileManager.default
        let directory = keyFilesDirectory
        
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
                return false
            }
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try key.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error saving key to \(filename): \(error)")
            return false
        }
    }
}
