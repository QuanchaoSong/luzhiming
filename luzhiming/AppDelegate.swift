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
    var statusItem: NSStatusItem!
    var settingsPopover: NSPopover?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 关闭所有默认窗口
        clearAllOtherWindows()
        
        // 创建圆形悬浮窗
        createFloatingWindow()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // 配置按钮
        if let button = statusItem.button {
            // 设置图标
            button.image = NSImage(named: "tray_icon") // 你的图标名称
            button.image?.size = NSSize(width: 18.0, height: 18.0) // 图标显示尺寸[^9^]
            //                    button.image?.isTemplate = true // 自动适配深浅色主题
            
            // 设置点击事件（左键和右键）
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // 支持左右键[^9^]
            
            // 设置悬停提示
            button.toolTip = "鹿之鸣"
        }
        
        // 再次确保关闭其他窗口
        DispatchQueue.main.async {
            //            self.clearAllOtherWindows()
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
            if (window != self.floatingWindow || window != self.statusItem) {
                window.close()
            }
        }
    }
    
    // 点击事件处理
    @objc func statusBarButtonClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .leftMouseUp {
            // 右键点击：显示菜单
            showMenu()
        } else {
            // 左键点击：显示/隐藏主窗口
            toggleMainWindow()
        }
    }
    
    // 显示菜单
    func showMenu() {
        let menu = NSMenu()
        
        // 添加菜单项
        let openItem = NSMenuItem(title: "设置", action: #selector(openSettingsPopover), keyEquivalent: "")
        openItem.target = self
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        
        // 弹出菜单
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // 触发显示
        statusItem.menu = nil // 重置，避免影响点击行为
    }
    
    // 切换主窗口显示
    @objc func toggleMainWindow() {
        //            if let window = mainWindow {
        //                if window.isVisible {
        //                    window.orderOut(nil)
        //                } else {
        //                    window.makeKeyAndOrderFront(nil)
        //                    NSApp.activate(ignoringOtherApps: true)
        //                }
        //            }
    }
    
    @objc func openMainWindow() {
        toggleMainWindow()
    }
    
    // MARK: - Settings Popover
    @objc func openSettingsPopover() {
        if settingsPopover == nil {
            let popover = NSPopover()
            popover.contentViewController = SettingsViewController()
            popover.behavior = .transient  // 点击外部自动关闭
            popover.contentSize = NSSize(width: 300, height: 200)
            settingsPopover = popover
        }
        
        // 在状态栏按钮处显示popover
        if let button = statusItem.button, let popover = settingsPopover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

