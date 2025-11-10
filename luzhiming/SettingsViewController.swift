//
//  SettingsViewController.swift
//  luzhiming
//

import Cocoa
import Foundation

// 自定义 NSSecureTextField 以支持垂直居中
class CenteredSecureTextField: NSSecureTextField {
    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        return NSSize(width: size.width, height: 24)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}

class SettingsViewController: NSViewController {
    
    // API Key 输入框容器
    private let zhipuContainer = NSView()
    
    // 内部输入框
    private var zhipuSecureField = CenteredSecureTextField()
    private var zhipuPlainField = NSTextField()
    
    // 显示/隐藏按钮
    private let zhipuToggleButton = NSButton()
    
    // 状态标志
    private var zhipuKeyVisible = false
    
    // 保存状态提示标签
    private let statusLabel = NSTextField()
    
    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedKeys()
    }
    
    private func setupUI() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "API 设置")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // ===== 智谱 API Key 区域 =====
        let zhipuLabel = NSTextField(labelWithString: "智谱 API Key")
        zhipuLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        zhipuLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(zhipuLabel)
        
        // 智谱输入框容器
        zhipuContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(zhipuContainer)
        
        setupKeyField(zhipuSecureField)
        zhipuSecureField.translatesAutoresizingMaskIntoConstraints = false
        zhipuContainer.addSubview(zhipuSecureField)
        
        setupKeyField(zhipuPlainField)
        zhipuPlainField.translatesAutoresizingMaskIntoConstraints = false
        zhipuContainer.addSubview(zhipuPlainField)
        
        zhipuToggleButton.title = "显示"
        zhipuToggleButton.setButtonType(.momentaryLight)
        zhipuToggleButton.bezelStyle = .rounded
        zhipuToggleButton.font = NSFont.systemFont(ofSize: 11)
        zhipuToggleButton.translatesAutoresizingMaskIntoConstraints = false
        zhipuToggleButton.action = #selector(toggleZhipuKeyVisibility)
        zhipuToggleButton.target = self
        view.addSubview(zhipuToggleButton)
        
        // ===== 保存按钮 =====
        let saveButton = NSButton()
        saveButton.title = "保存"
        saveButton.setButtonType(.momentaryPushIn)
        saveButton.bezelStyle = .rounded
        saveButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.action = #selector(saveSettings)
        saveButton.target = self
        view.addSubview(saveButton)
        
        // ===== 状态提示标签 =====
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.isEditable = false
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(statusLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 标题
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            
            // 智谱标签
            zhipuLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            zhipuLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            
            // 智谱输入框容器
            zhipuContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            zhipuContainer.topAnchor.constraint(equalTo: zhipuLabel.bottomAnchor, constant: 6),
            zhipuContainer.widthAnchor.constraint(equalToConstant: 200),
            zhipuContainer.heightAnchor.constraint(equalToConstant: 24),
            
            // 智谱显示按钮
            zhipuToggleButton.leadingAnchor.constraint(equalTo: zhipuContainer.trailingAnchor, constant: 8),
            zhipuToggleButton.centerYAnchor.constraint(equalTo: zhipuContainer.centerYAnchor),
            zhipuToggleButton.widthAnchor.constraint(equalToConstant: 50),
            
            // 保存按钮
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.topAnchor.constraint(equalTo: zhipuContainer.bottomAnchor, constant: 30),
            saveButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -15),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            
            // 状态提示标签
            statusLabel.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 12),
            statusLabel.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
        ])
        
        // 容器内部约束
        NSLayoutConstraint.activate([
            zhipuSecureField.leadingAnchor.constraint(equalTo: zhipuContainer.leadingAnchor),
            zhipuSecureField.topAnchor.constraint(equalTo: zhipuContainer.topAnchor),
            zhipuSecureField.bottomAnchor.constraint(equalTo: zhipuContainer.bottomAnchor),
            zhipuSecureField.trailingAnchor.constraint(equalTo: zhipuContainer.trailingAnchor),
            
            zhipuPlainField.leadingAnchor.constraint(equalTo: zhipuContainer.leadingAnchor),
            zhipuPlainField.topAnchor.constraint(equalTo: zhipuContainer.topAnchor),
            zhipuPlainField.bottomAnchor.constraint(equalTo: zhipuContainer.bottomAnchor),
            zhipuPlainField.trailingAnchor.constraint(equalTo: zhipuContainer.trailingAnchor),
        ])
        
        // 初始状态：显示密码框，隐藏明文框
        zhipuPlainField.isHidden = true
    }
    
    private func setupKeyField(_ field: NSTextField) {
        field.bezelStyle = .squareBezel
        field.isBordered = true
        field.font = NSFont.systemFont(ofSize: 12)
        field.alignment = .left
        
        // 对 NSSecureTextField 应用垂直居中
        if let secureField = field as? NSSecureTextField {
            if let cell = secureField.cell {
                cell.controlSize = .small
            }
        }
    }
    
    // MARK: - 显示/隐藏API Key
    @objc private func toggleZhipuKeyVisibility() {
        zhipuKeyVisible = !zhipuKeyVisible
        updateZhipuKeyFieldVisibility()
        zhipuToggleButton.title = zhipuKeyVisible ? "隐藏" : "显示"
    }
    
    private func updateZhipuKeyFieldVisibility() {
        // 同步两个字段的值
        let currentValue = zhipuKeyVisible ? zhipuSecureField.stringValue : zhipuPlainField.stringValue
        zhipuSecureField.stringValue = currentValue
        zhipuPlainField.stringValue = currentValue
        
        // 切换显示
        zhipuSecureField.isHidden = zhipuKeyVisible
        zhipuPlainField.isHidden = !zhipuKeyVisible
        
        // 获取焦点
        if zhipuKeyVisible {
            NSApplication.shared.mainWindow?.makeFirstResponder(zhipuPlainField)
        } else {
            NSApplication.shared.mainWindow?.makeFirstResponder(zhipuSecureField)
        }
    }
    
    // MARK: - 保存设置
    @objc private func saveSettings() {
        let zhipuKey = zhipuKeyVisible ? zhipuPlainField.stringValue : zhipuSecureField.stringValue
        
        // 验证输入
        guard !zhipuKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            showStatus("智谱 API Key 不能为空", isError: true)
            return
        }
        
        // 保存到本地文件
        let success = LocalKeysTool.shared.saveZhipuAPIKey(zhipuKey)
        
        if success {
            showStatus("保存成功", isError: false)
        } else {
            showStatus("保存失败", isError: true)
        }
    }
    
    // MARK: - 加载保存的设置
    private func loadSavedKeys() {
        if let zhipuKey = LocalKeysTool.shared.getZhipuAPIKey() {
            zhipuSecureField.stringValue = zhipuKey
            zhipuPlainField.stringValue = zhipuKey
        }
    }
    
    private func showStatus(_ message: String, isError: Bool) {
        statusLabel.stringValue = message
        statusLabel.textColor = isError ? NSColor.red : NSColor.green
        
        // 5秒后清除提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.statusLabel.stringValue = ""
        }
    }
}
