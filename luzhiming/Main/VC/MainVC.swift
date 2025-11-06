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
        
//        AF.request("https://api2.serverpulse.work/health").response { resp in
//            if let error = resp.error {
//                print("Request failed: \(error)")
//            } else {
//                print("Request ok, status: \(resp.response?.statusCode ?? -1)")
//            }
//        }

        // 如需使用智谱 ASR，请先设置 API Key（也可通过环境变量 ZHIPU_API_KEY 提供）
        // HttpDiggerZhipu.shared.configure(apiKey: "zhipu-xxxxxxxx")

        // 示例：尝试把最新一条 WAV 录音发送到智谱 ASR（过滤只取 .wav）
        if let lastURL = AudioRecordTool.shared.recordingFiles.last(where: { $0.pathExtension.lowercased() == "wav" }) {
            print("lastWavURL: \(lastURL)")
            HttpDiggerZhipu.shared.transcribe(fileURL: lastURL) { result in
                switch result {
                case .success(let resp):
                    print("[ZHIPU ASR] text=\(resp.text ?? "<nil>")")
                    if let segs = resp.segments, !segs.isEmpty {
                        print("[ZHIPU ASR] segments: \(segs.count)")
                    }
                case .failure(let error):
                    print("[ZHIPU ASR] failed: \(error.localizedDescription)")
                }
            }
        } else {
            print("[ZHIPU ASR] 暂无 WAV 录音文件可用于转写")
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
}
