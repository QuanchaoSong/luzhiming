//
//  AppDelegate.swift
//  luzhiming
//
//  Created by Albus on 2025/11/3.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var floatingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 关闭所有默认窗口
        clearAllOtherWindows()
        
        // 创建圆形悬浮窗
        createFloatingWindow()
        
        // 再次确保关闭其他窗口
        DispatchQueue.main.async {
            self.clearAllOtherWindows()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // 防止应用因为关闭窗口而退出
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // 禁用自动窗口恢复
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            floatingWindow?.orderFront(nil)
        }
        return true
    }
    
    private func createFloatingWindow() {
        // 设置窗口尺寸和位置
        let windowSize = NSSize(width: 80, height: 80)  // 临时改成更小的尺寸来验证
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowFrame = NSRect(
            x: screenFrame.width - windowSize.width - 40,
            y: screenFrame.height - windowSize.height - 40,
            width: windowSize.width,
            height: windowSize.height
        )
        
        // 创建窗口，去除所有装饰
        floatingWindow = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        floatingWindow?.isOpaque = false
        floatingWindow?.backgroundColor = NSColor.clear
        floatingWindow?.level = NSWindow.Level.floating
        floatingWindow?.isMovableByWindowBackground = false  // 禁用默认拖动
        floatingWindow?.hasShadow = false  // 关闭阴影避免影响尺寸
        floatingWindow?.canHide = false
        floatingWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // 强制设置窗口大小，忽略系统最小尺寸限制
        floatingWindow?.setContentSize(windowSize)
        floatingWindow?.minSize = NSSize(width: 1, height: 1)  // 设置最小尺寸为1x1
        floatingWindow?.maxSize = windowSize
        
        // 创建视图控制器
        let viewController = MainVC()
        floatingWindow?.contentViewController = viewController
        
        // 再次强制设置窗口尺寸
        floatingWindow?.setFrame(windowFrame, display: false)
        
        // 显示窗口 (不设置为 key window 以避免警告)
        floatingWindow?.orderFront(nil)
        
        // 最后一次确保窗口尺寸
        DispatchQueue.main.async {
            self.floatingWindow?.setContentSize(windowSize)
        }
        
        // 隐藏dock图标和菜单栏（可选）
        NSApp.setActivationPolicy(.accessory)
    }
    
    func clearAllOtherWindows() {
        for window in NSApp.windows {
            if window != self.floatingWindow {
                window.close()
            }
        }
    }
}

