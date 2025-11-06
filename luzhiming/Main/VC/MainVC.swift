//
//  MainVC.swift
//  luzhiming
//
//  Created by Albus on 2025/11/4.
//

import Cocoa
import Alamofire

class MainVC: NSViewController {
    
    private var circleView: CircleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircleView()
        
        // 录音完成后，自动调用智谱 ASR 进行转写
        AudioRecordTool.shared.onRecordingCompleted = { fileURL in
            self.transcribeAudioWithZhipu(fileURL: fileURL);
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // 调试：打印实际视图尺寸
        print("View frame: \(view.frame)")
        print("Window frame: \(view.window?.frame ?? NSRect.zero)")
    }
    
    private func setupCircleView() {
        // 创建圆形视图
        circleView = CircleView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleView)
        
        // 将点击行为移动到这里：点击圆形视图时切换录音
        circleView.onTap = {
            AudioRecordTool.shared.toggleRecording()
        }
        
        // 设置约束，让圆形视图填满整个窗口
        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: view.topAnchor),
            circleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            circleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            circleView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func transcribeAudioWithZhipu(fileURL: URL) {
        print("[ZHIPU ASR] 开始转写: \(fileURL.lastPathComponent)")
        HttpDiggerZhipu.shared.transcribe(fileURL: fileURL) { result in
            switch result {
            case .success(let resp):
                let text = resp.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !text.isEmpty {
                    print("[ZHIPU ASR] text=\(text)")
                    GlobalTool.copyToClipboard(text)
                    print("[ZHIPU ASR] 已复制到剪贴板")
                } else {
                    print("[ZHIPU ASR] 未返回可用文本")
                }
            case .failure(let error):
                print("[ZHIPU ASR] failed: \(error.localizedDescription)")
            }
        }
    }
}
