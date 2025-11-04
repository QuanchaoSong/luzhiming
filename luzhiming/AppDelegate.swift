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
        for window in NSApp.windows {
            if window != floatingWindow {
                window.close()
            }
        }
        
        // 创建圆形悬浮窗
        createFloatingWindow()
        
        // 再次确保关闭其他窗口
        DispatchQueue.main.async {
            for window in NSApp.windows {
                if window != self.floatingWindow {
                    window.close()
                }
            }
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
            floatingWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    private func createFloatingWindow() {
        // 设置窗口尺寸和位置
        let windowSize = NSSize(width: 30, height: 30)
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowFrame = NSRect(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2,
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
        floatingWindow?.hasShadow = true
        floatingWindow?.canHide = false
        floatingWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // 设置窗口大小限制，确保不能调整大小
        floatingWindow?.minSize = windowSize
        floatingWindow?.maxSize = windowSize
        
        // 创建视图控制器
        let viewController = ViewController()
        floatingWindow?.contentViewController = viewController
        
        // 显示窗口
        floatingWindow?.makeKeyAndOrderFront(nil)
        
        // 隐藏dock图标和菜单栏（可选）
        NSApp.setActivationPolicy(.accessory)
    }
}

