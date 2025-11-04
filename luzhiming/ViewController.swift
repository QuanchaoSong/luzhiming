//
//  ViewController.swift
//  luzhiming
//
//  Created by Albus on 2025/11/3.
//

import Cocoa

class ViewController: NSViewController {
    
    private var circleView: CircleView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircleView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func setupCircleView() {
        // 创建圆形视图
        circleView = CircleView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleView)
        
        // 设置约束，让圆形视图填满整个窗口
        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: view.topAnchor),
            circleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            circleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            circleView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// 自定义圆形视图
class CircleView: NSView {
    
    private var isDragging = false
    private var dragOffset = NSPoint.zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        
        // 移除手动设置frame，让自动布局来决定大小
        // self.frame = CGRect(origin: .zero, size: size) // 删除这行
        
        // 圆形半径动态计算，取宽高的一半中的较小值
        updateCornerRadius()
        
        layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        layer?.borderWidth = 1 // 调整边框宽度，适应小尺寸
        layer?.borderColor = NSColor.white.cgColor
        
        // 添加阴影
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.3
        layer?.shadowOffset = NSSize(width: 0, height: -1) // 调整阴影偏移
        layer?.shadowRadius = 2 // 调整阴影半径
        
        // 确保图层不会超出边界
        layer?.masksToBounds = false
    }
    
    // 动态更新圆角半径
    private func updateCornerRadius() {
        let radius = min(bounds.width, bounds.height) / 2
        layer?.cornerRadius = radius
    }
    
    override func layout() {
        super.layout()
        // 当视图大小改变时，更新圆角半径
        updateCornerRadius()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制圆形
        let path = NSBezierPath(ovalIn: bounds)
        NSColor.systemBlue.withAlphaComponent(0.8).setFill()
        path.fill()
        
        // 绘制边框
        NSColor.white.setStroke()
        path.lineWidth = 1 // 调整边框宽度
        path.stroke()
        
        // 在圆形中心绘制一个小点，大小根据圆形大小调整
        let centerPoint = NSPoint(x: bounds.midX, y: bounds.midY)
        let dotRadius = max(1, min(bounds.width, bounds.height) * 0.1) // 动态计算点的大小，约为圆形大小的10%
        let dotRect = NSRect(
            x: centerPoint.x - dotRadius,
            y: centerPoint.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        let dotPath = NSBezierPath(ovalIn: dotRect)
        NSColor.white.setFill()
        dotPath.fill()
    }
    
    // MARK: - 鼠标事件处理（拖动功能）
    
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
    
    // 鼠标悬停效果（可选）
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(1.0).cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除现有的跟踪区域
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        // 添加新的跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
}

