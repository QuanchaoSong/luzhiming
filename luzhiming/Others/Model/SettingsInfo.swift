import Foundation

enum ApiKeyProvider: String, Codable {
    case zhipu
    case openai
    case doubao
}

class SettingsInfo: Codable {
    
    // MARK: - Properties
    
    /// 语音服务提供商
    var apiKeyProvider: ApiKeyProvider = .zhipu {
        didSet { saveToDisk() }
    }
    
    /// 音频录音缓存文件夹最大文件数
    var maxAudioRecordings: Int = 50 {
        didSet { saveToDisk() }
    }
    
    /// 录音最短时长（秒）
    var minRecordingDuration: Double = 1.0 {
        didSet { saveToDisk() }
    }
    
    /// 录音最长时长（秒），默认 60 秒
    var maxRecordingDuration: Double = 60.0 {
        didSet { saveToDisk() }
    }
    
    /// 是否自动清理旧录音
    var autoCleanOldRecordings: Bool = true {
        didSet { saveToDisk() }
    }
    
    // MARK: - Singleton
    static let shared = SettingsInfo()
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Persistence
    
    private var settingsFileURL: URL {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let luzimingDir = homeDir.appendingPathComponent(".luzhiming")
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: luzimingDir.path) {
            try? fileManager.createDirectory(at: luzimingDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return luzimingDir.appendingPathComponent("settings.json")
    }
    
    /// 保存设置到磁盘
    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(self)
            try data.write(to: settingsFileURL, options: .atomic)
            print("✅ 设置已保存到: \(settingsFileURL.path)")
        } catch {
            print("❌ 保存设置失败: \(error)")
        }
    }
    
    /// 从磁盘加载设置
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: settingsFileURL.path) else {
            print("ℹ️ 设置文件不存在，使用默认配置")
            // 首次运行，保存默认配置
            saveToDisk()
            return
        }
        
        do {
            let data = try Data(contentsOf: settingsFileURL)
            let decoder = JSONDecoder()
            let loaded = try decoder.decode(SettingsInfo.self, from: data)
            
            // 将加载的值应用到当前实例（不触发 didSet）
            self.apiKeyProvider = loaded.apiKeyProvider
            self.maxAudioRecordings = loaded.maxAudioRecordings
            self.minRecordingDuration = loaded.minRecordingDuration
            self.maxRecordingDuration = loaded.maxRecordingDuration
            self.autoCleanOldRecordings = loaded.autoCleanOldRecordings
            
            print("✅ 设置已加载: \(settingsFileURL.path)")
        } catch {
            print("⚠️ 加载设置失败，使用默认配置: \(error)")
            saveToDisk()
        }
    }
    
    // MARK: - Helper Methods
    
    /// 重置为默认设置
    func resetToDefaults() {
        apiKeyProvider = .zhipu
        maxAudioRecordings = 50
        minRecordingDuration = 1.0
        maxRecordingDuration = 60.0
        autoCleanOldRecordings = true
        // saveToDisk() 会在 didSet 中自动调用
    }
    
    /// 获取音频录音缓存目录
    func getAudioRecordingsDirectory() -> URL {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let luzimingDir = homeDir.appendingPathComponent(".luzhiming")
        let recordingsDir = luzimingDir.appendingPathComponent("audio_recordings")
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return recordingsDir
    }
    
    /// 清理超出数量限制的旧录音文件
    func cleanupOldRecordings() {
        guard autoCleanOldRecordings else { return }
        
        let recordingsDir = getAudioRecordingsDirectory()
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            // 按创建日期排序（旧的在前）
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 < date2
            }
            
            // 删除超出数量的旧文件
            if sortedFiles.count > maxAudioRecordings {
                let filesToDelete = sortedFiles.prefix(sortedFiles.count - maxAudioRecordings)
                for file in filesToDelete {
                    try? fileManager.removeItem(at: file)
                    print("🗑️ 已删除旧录音: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("❌ 清理录音文件失败: \(error)")
        }
    }
}
