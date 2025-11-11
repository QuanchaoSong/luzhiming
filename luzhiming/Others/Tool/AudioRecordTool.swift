//
//  AudioRecordTool.swift
//  luzhiming
//
//  Created by Albus on 2025/11/5.
//

import Foundation
import AVFoundation

class AudioRecordTool {
    
    // MARK: - 单例
    static let shared = AudioRecordTool()
    
    // MARK: - 属性
    private var audioRecorder: AVAudioRecorder?
    private(set) var isRecording = false
    private var currentRecordingURL: URL?
    
    // 录音计时器
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var currentRecordingDuration: TimeInterval = 0
    
    // 存储所有录音文件的列表
    private(set) var recordingFiles: [URL] = []
    
    // 录音状态回调
    var onRecordingStateChanged: ((Bool) -> Void)?
    // 录音完成回调（返回生成的文件 URL）
    var onRecordingCompleted: ((URL) -> Void)?
    // 录音时长更新回调（每0.1秒触发一次，参数为当前录音时长）
    var onRecordingDurationUpdated: ((TimeInterval) -> Void)?
    // 录音时长不足回调
    var onRecordingTooShort: ((TimeInterval, TimeInterval) -> Void)? // (实际时长, 最短时长)
    
    // MARK: - 初始化
    private init() {
        requestMicrophonePermission()
        loadRecordingHistory()
    }
    
    // MARK: - 录音历史管理
    
    private func loadRecordingHistory() {
        // 从 UserDefaults 加载历史录音文件列表
        if let savedPaths = UserDefaults.standard.array(forKey: "RecordingFiles") as? [String] {
            recordingFiles = savedPaths.compactMap { URL(fileURLWithPath: $0) }
            print("📚 加载了 \(recordingFiles.count) 个历史录音文件")
        }
    }
    
    private func saveRecordingHistory() {
        let paths = recordingFiles.map { $0.path }
        UserDefaults.standard.set(paths, forKey: "RecordingFiles")
        print("💾 录音历史已保存")
    }
    
    private func addRecordingFile(_ url: URL) {
        recordingFiles.append(url)
        saveRecordingHistory()
        
        print("📝 录音文件已保存:")
        print("   文件路径: \(url.path)")
        print("   文件名: \(url.lastPathComponent)")
        print("   总录音数: \(recordingFiles.count)")
        
        // 打印所有录音文件列表
        print("\n📋 所有录音文件:")
        for (index, file) in recordingFiles.enumerated() {
            print("   \(index + 1). \(file.lastPathComponent)")
        }
        print("")
    }
    
    // MARK: - 权限请求
    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("✅ 麦克风权限已授予")
            } else {
                print("❌ 麦克风权限被拒绝")
            }
        }
    }
    
    // MARK: - 路径与目录
    private var baseDirectory: URL {
        // ~/.luzhiming
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".luzhiming", isDirectory: true)
    }
    
    private var audioRecordingsDirectory: URL {
        // ~/.luzhiming/audio_recordings
        baseDirectory.appendingPathComponent("audio_recordings", isDirectory: true)
    }
    
    private func ensureAppDirectories() {
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: baseDirectory.path) {
                try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
                print("📁 已创建目录: \(baseDirectory.path)")
            }
            if !fm.fileExists(atPath: audioRecordingsDirectory.path) {
                try fm.createDirectory(at: audioRecordingsDirectory, withIntermediateDirectories: true)
                print("📁 已创建目录: \(audioRecordingsDirectory.path)")
            }
        } catch {
            print("❌ 创建应用目录失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 录音控制
    
    /// 开始录音
    func startRecording() {
        if (AVCaptureDevice.authorizationStatus(for: .audio) != .authorized) {
            print("❌ 无麦克风权限，无法录音")
            return
        }
        
        guard !isRecording else {
            print("⚠️ 已在录音中")
            return
        }
        
        print("🎤 开始录音")
        
        // 确保目录存在：~/.luzhiming/audio_recordings/
        ensureAppDirectories()
        
        // 设置录音文件路径到 ~/.luzhiming/audio_recordings/
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        // 使用 WAV（Linear PCM），便于后端（如智谱 ASR）直接识别
        let audioFilename = audioRecordingsDirectory.appendingPathComponent("recording_\(dateString).wav")
        
        // 保存当前录音的 URL
        currentRecordingURL = audioFilename
        
        // 录音设置（WAV / Linear PCM，16-bit，单声道，16kHz）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // 启动计时器
            recordingStartTime = Date()
            currentRecordingDuration = 0
            startRecordingTimer()
            
            onRecordingStateChanged?(true)
            print("✅ 录音已开始")
            print("   文件将保存至: \(audioFilename.path)")
            print("   最短时长: \(SettingsInfo.shared.minRecordingDuration)秒")
            print("   最长时长: \(SettingsInfo.shared.maxRecordingDuration)秒")
        } catch {
            print("❌ 录音失败: \(error.localizedDescription)")
            isRecording = false
            currentRecordingURL = nil
            onRecordingStateChanged?(false)
        }
    }
    
    /// 停止录音
    func stopRecording() {
        guard isRecording else {
            print("⚠️ 当前未在录音")
            return
        }
        
        print("⏹️ 停止录音")
        
        // 停止计时器
        stopRecordingTimer()
        
        audioRecorder?.stop()
        
        // 检查录音时长
        let minDuration = SettingsInfo.shared.minRecordingDuration
        if currentRecordingDuration < minDuration {
            print("⚠️ 录音时长不足: \(String(format: "%.2f", currentRecordingDuration))秒 < \(minDuration)秒")
            
            // 删除录音文件
            if let url = currentRecordingURL {
                try? FileManager.default.removeItem(at: url)
                print("🗑️ 已删除时长不足的录音文件")
            }
            
            // 回调：录音时长不足
            onRecordingTooShort?(currentRecordingDuration, minDuration)
            
            // 清理状态
            cleanupRecordingState()
            return
        }
        
        // 保存录音文件记录
        if let url = currentRecordingURL, FileManager.default.fileExists(atPath: url.path) {
            addRecordingFile(url)
            
            // 获取文件大小
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 {
                let sizeInMB = Double(fileSize) / 1024.0 / 1024.0
                print("   文件大小: \(String(format: "%.2f", sizeInMB)) MB")
            }
            print("   录音时长: \(String(format: "%.2f", currentRecordingDuration))秒")

            // 回调：录音完成，返回文件 URL
            onRecordingCompleted?(url)
            
            // 自动清理旧录音
            SettingsInfo.shared.cleanupOldRecordings()
        } else {
            print("⚠️ 录音文件不存在或未保存")
        }
        
        // 清理状态
        cleanupRecordingState()
    }
    
    // MARK: - 录音计时器
    
    private func startRecordingTimer() {
        // 创建定时器，每 0.1 秒触发一次
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 计算录音时长
            if let startTime = self.recordingStartTime {
                self.currentRecordingDuration = Date().timeIntervalSince(startTime)
                
                // 回调：时长更新
                self.onRecordingDurationUpdated?(self.currentRecordingDuration)
                
                // 检查是否超过最长时长
                let maxDuration = SettingsInfo.shared.maxRecordingDuration
                if self.currentRecordingDuration >= maxDuration {
                    print("⏱️ 已达到最长录音时长: \(maxDuration)秒，自动停止")
                    self.stopRecording()
                }
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func cleanupRecordingState() {
        audioRecorder = nil
        currentRecordingURL = nil
        recordingStartTime = nil
        currentRecordingDuration = 0
        isRecording = false
        onRecordingStateChanged?(false)
    }
    
    /// 切换录音状态
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    /// 获取当前录音时长
    func getCurrentRecordingDuration() -> TimeInterval {
        return currentRecordingDuration
    }
    
    /// 获取录音剩余时长（最大时长 - 当前时长）
    func getRemainingRecordingDuration() -> TimeInterval {
        let maxDuration = SettingsInfo.shared.maxRecordingDuration
        return max(0, maxDuration - currentRecordingDuration)
    }
}
