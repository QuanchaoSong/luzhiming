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
    
    // 存储所有录音文件的列表
    private(set) var recordingFiles: [URL] = []
    
    // 录音状态回调
    var onRecordingStateChanged: ((Bool) -> Void)?
    
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
        
        // 设置录音文件路径
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let audioFilename = documentsPath.appendingPathComponent("recording_\(dateString).m4a")
        
        // 保存当前录音的 URL
        currentRecordingURL = audioFilename
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            onRecordingStateChanged?(true)
            print("✅ 录音已开始")
            print("   文件将保存至: \(audioFilename.path)")
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
        
        audioRecorder?.stop()
        
        // 保存录音文件记录
        if let url = currentRecordingURL, FileManager.default.fileExists(atPath: url.path) {
            addRecordingFile(url)
            
            // 获取文件大小
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 {
                let sizeInMB = Double(fileSize) / 1024.0 / 1024.0
                print("   文件大小: \(String(format: "%.2f", sizeInMB)) MB")
            }
        } else {
            print("⚠️ 录音文件不存在或未保存")
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
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
}
