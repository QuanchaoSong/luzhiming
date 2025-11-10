//
//  SettingsViewController.swift
//  luzhiming
//

import Cocoa

class SettingsViewController: NSViewController {
    
    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 添加标题标签
        let titleLabel = NSTextField(labelWithString: "设置")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // 添加内容标签
        let contentLabel = NSTextField(wrappingLabelWithString: "这是一个设置窗口的占位符\n你可以在这里添加各种设置项")
        contentLabel.font = NSFont.systemFont(ofSize: 13)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentLabel)
        
        // 布局
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            
            contentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15)
        ])
    }
}
