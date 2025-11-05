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
    
    // 录音状态回调
    var onRecordingStateChanged: ((Bool) -> Void)?
    
    // MARK: - 初始化
    private init() {
        requestMicrophonePermission()
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
        guard !isRecording else {
            print("⚠️ 已在录音中")
            return
        }
        
        print("🎤 开始录音")
        
        // 设置录音文件路径
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
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
            print("✅ 录音已开始，文件路径: \(audioFilename)")
        } catch {
            print("❌ 录音失败: \(error.localizedDescription)")
            isRecording = false
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
        audioRecorder = nil
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
