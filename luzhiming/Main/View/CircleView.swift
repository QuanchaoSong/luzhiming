//
//  CircleView.swift
//  luzhiming
//
//  Created by Albus on 2025/11/5.
//

import Cocoa

class CircleView: NSView {
    
    private var isDragging = false
    private var dragOffset = NSPoint.zero
    
    // 点击事件回调，由外部（如 MainVC）注入具体行为
    var onTap: (() -> Void)?
    
    // 颜色定义
    private let idleColor = NSColor.systemPurple.withAlphaComponent(0.8)
    private let recordingColor = NSColor.systemOrange.withAlphaComponent(0.8)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupRecordingCallback()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupRecordingCallback()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 40
        layer?.backgroundColor = idleColor.cgColor
        
        // 添加边框
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.16).cgColor
    }
    
    private func setupRecordingCallback() {
        // 监听录音状态变化
        AudioRecordTool.shared.onRecordingStateChanged = { [weak self] isRecording in
            DispatchQueue.main.async {
                self?.updateColor(isRecording: isRecording)
            }
        }
    }
    
    override func layout() {
        super.layout()
        // 调试：打印实际尺寸
        print("CircleView bounds: \(bounds)")
    }
    
    // MARK: - 拖动功能
    
    override func mouseDown(with event: NSEvent) {
        isDragging = false  // 重置拖动状态
        let mouseLocationInWindow = event.locationInWindow
        dragOffset = NSPoint(
            x: mouseLocationInWindow.x,
            y: mouseLocationInWindow.y
        )
    }
    
    override func mouseDragged(with event: NSEvent) {
        isDragging = true  // 只有在拖动时才标记为 true
        guard let window = self.window else { return }
        
        let mouseLocationInScreen = NSEvent.mouseLocation
        let newWindowOrigin = NSPoint(
            x: mouseLocationInScreen.x - dragOffset.x,
            y: mouseLocationInScreen.y - dragOffset.y
        )
        
        window.setFrameOrigin(newWindowOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        // 只有在没有拖动的情况下才切换录音状态
        if !isDragging {
            onTap?()
        }
        isDragging = false
    }
    
    // MARK: - 颜色更新
    
    private func updateColor(isRecording: Bool) {
        let newColor = isRecording ? recordingColor : idleColor
        
        // 添加动画效果
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.layer?.backgroundColor = newColor.cgColor
        }
    }
}
