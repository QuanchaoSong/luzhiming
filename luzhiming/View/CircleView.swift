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
    private var randomColor: NSColor
    
    override init(frame frameRect: NSRect) {
        // 生成随机颜色
        randomColor = NSColor(
            red: CGFloat.random(in: 0.3...1.0),
            green: CGFloat.random(in: 0.3...1.0),
            blue: CGFloat.random(in: 0.3...1.0),
            alpha: 0.8
        )
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        randomColor = NSColor.systemBlue.withAlphaComponent(0.8)
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 40
        layer?.backgroundColor = randomColor.cgColor
        
        // 添加边框以便更清楚地看到尺寸
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.16).cgColor
    }
    
    override func layout() {
        super.layout()
        // 调试：打印实际尺寸
        print("CircleView bounds: \(bounds)")
    }
    
    // MARK: - 拖动功能
    
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        let mouseLocationInWindow = event.locationInWindow
        dragOffset = NSPoint(
            x: mouseLocationInWindow.x,
            y: mouseLocationInWindow.y
        )
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let window = self.window else { return }
        
        let mouseLocationInScreen = NSEvent.mouseLocation
        let newWindowOrigin = NSPoint(
            x: mouseLocationInScreen.x - dragOffset.x,
            y: mouseLocationInScreen.y - dragOffset.y
        )
        
        window.setFrameOrigin(newWindowOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}
