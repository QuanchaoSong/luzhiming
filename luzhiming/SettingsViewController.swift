//
//  SettingsViewController.swift
//  luzhiming
//

import Cocoa
import Foundation

// MARK: - 厂商数据模型
struct APIProvider {
    let name: String
    let identifier: String
}

// MARK: - 厂商卡片视图
class ProviderCardView: NSView {
    let provider: APIProvider
    private(set) var isSelected: Bool = false
    
    private let titleLabel = NSTextField()
    private let apiKeyField = NSTextField()
    private let selectedCheckbox = NSButton()
    
    private var onSelectionChanged: ((Bool) -> Void)?
    
    init(provider: APIProvider) {
        self.provider = provider
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 标题
        titleLabel.stringValue = provider.name
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // API Key 输入框
        apiKeyField.bezelStyle = .squareBezel
        apiKeyField.isBordered = true
        apiKeyField.font = NSFont.systemFont(ofSize: 11)
        apiKeyField.placeholderString = "输入 \(provider.name) API Key"
        apiKeyField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(apiKeyField)
        
        // 选择开关
        selectedCheckbox.setButtonType(.switch)
        selectedCheckbox.title = "使用此服务"
        selectedCheckbox.font = NSFont.systemFont(ofSize: 11)
        selectedCheckbox.translatesAutoresizingMaskIntoConstraints = false
        selectedCheckbox.action = #selector(checkboxToggled)
        selectedCheckbox.target = self
        addSubview(selectedCheckbox)
        
        // 布局
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            
            apiKeyField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            apiKeyField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            apiKeyField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            apiKeyField.heightAnchor.constraint(equalToConstant: 22),
            
            selectedCheckbox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            selectedCheckbox.topAnchor.constraint(equalTo: apiKeyField.bottomAnchor, constant: 6),
            selectedCheckbox.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    func setAPIKey(_ key: String) {
        apiKeyField.stringValue = key
    }
    
    func getAPIKey() -> String {
        return apiKeyField.stringValue
    }
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        selectedCheckbox.state = selected ? .on : .off
        updateCardAppearance()
    }
    
    func onSelectionChanged(_ callback: @escaping (Bool) -> Void) {
        self.onSelectionChanged = callback
    }
    
    @objc private func checkboxToggled() {
        isSelected = selectedCheckbox.state == .on
        updateCardAppearance()
        onSelectionChanged?(isSelected)
    }
    
    private func updateCardAppearance() {
        if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            titleLabel.textColor = NSColor.white
            apiKeyField.textColor = NSColor.white
            selectedCheckbox.attributedTitle = NSAttributedString(
                string: "使用此服务",
                attributes: [.foregroundColor: NSColor.white]
            )
        } else {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            titleLabel.textColor = NSColor.labelColor
            apiKeyField.textColor = NSColor.labelColor
            selectedCheckbox.attributedTitle = NSAttributedString(
                string: "使用此服务",
                attributes: [.foregroundColor: NSColor.labelColor]
            )
        }
    }
}

class SettingsViewController: NSViewController {
    
    // 侧边栏
    private let sidebarView = NSView()
    private let sidebarStackView = NSStackView()
    
    // 内容区域
    private let contentView = NSView()
    private let contentScrollView = NSScrollView()
    private let contentStackView = NSStackView()
    
    // 状态标签
    private let statusLabel = NSTextField()
    
    // 厂商卡片
    private var providerCards: [String: ProviderCardView] = [:]
    
    // 保存按钮
    private let saveButton = NSButton()
    
    // 设置分类
    private let categories = ["API Keys", "时间设置", "清理缓存"]
    
    // 当前选中的类别
    private var currentCategory: String = "API Keys"
    
    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 扩展设置窗口默认尺寸，避免过窄
        self.preferredContentSize = NSSize(width: 720, height: 520)
        setupUI()
        loadSavedKeys()
    }
    
    private func setupUI() {
        // 主容器 - 横向分割
        let mainContainer = NSView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        // ===== 侧边栏设置 =====
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.wantsLayer = true
        sidebarView.layer?.backgroundColor = NSColor.separatorColor.cgColor
        mainContainer.addSubview(sidebarView)
        
        sidebarStackView.orientation = .vertical
        sidebarStackView.spacing = 6
        sidebarStackView.distribution = .equalSpacing
        sidebarStackView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(sidebarStackView)
        
        // 创建分类按钮
        for (index, category) in categories.enumerated() {
            let button = NSButton()
            button.title = category
            button.setButtonType(.momentaryChange)
            button.bezelStyle = .rounded
            button.font = NSFont.systemFont(ofSize: 11)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.action = #selector(categoryButtonClicked(_:))
            button.target = self
            button.tag = index
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            sidebarStackView.addArrangedSubview(button)
        }
        
        // 侧边栏约束
        NSLayoutConstraint.activate([
            sidebarStackView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 12),
            sidebarStackView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -12),
            sidebarStackView.topAnchor.constraint(equalTo: sidebarView.topAnchor, constant: 20),
            sidebarStackView.bottomAnchor.constraint(lessThanOrEqualTo: sidebarView.bottomAnchor, constant: -20),

            sidebarView.widthAnchor.constraint(equalToConstant: 150),
            sidebarView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            sidebarView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
        ])
        
        // ===== 内容区域设置 =====
        contentView.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(contentView)
        
        // 滚动视图
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.hasVerticalScroller = true
        contentScrollView.hasHorizontalScroller = false
        contentScrollView.autohidesScrollers = true
        contentView.addSubview(contentScrollView)
        
        // 内容堆栈视图 - 改为 .top 分布
        contentStackView.orientation = .vertical
        contentStackView.spacing = 10
        contentStackView.distribution = .fill
        contentStackView.alignment = .leading
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.documentView = contentStackView
        
        // 内容区域约束
        NSLayoutConstraint.activate([
        contentScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
        contentScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
        contentScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
        contentScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -72),
            
            contentView.leadingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
        ])
        
        // ===== 保存按钮和状态标签 =====
        saveButton.title = "保存"
        saveButton.setButtonType(.momentaryPushIn)
        saveButton.bezelStyle = .rounded
        saveButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.action = #selector(saveSettings)
        saveButton.target = self
        contentView.addSubview(saveButton)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.isEditable = false
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
        saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
        saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            saveButton.widthAnchor.constraint(equalToConstant: 70),
            saveButton.heightAnchor.constraint(equalToConstant: 24),
            
            statusLabel.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
        ])
        
        // 主容器约束
        NSLayoutConstraint.activate([
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // 初始化 API Keys 分类
        showAPIKeysCategory()
    }
    
    @objc private func categoryButtonClicked(_ sender: NSButton) {
        guard sender.tag < categories.count else { return }
        currentCategory = categories[sender.tag]
        
        // 清空内容
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        providerCards.removeAll()
        statusLabel.stringValue = ""
        
        switch currentCategory {
        case "API Keys":
            showAPIKeysCategory()
        case "时间设置":
            showTimeSettingsCategory()
        case "清理缓存":
            showClearCacheCategory()
        default:
            break
        }
    }
    
    private func showAPIKeysCategory() {
        // 标题
    let titleLabel = NSTextField(labelWithString: "选择 API 服务商")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(titleLabel)
        titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // 创建厂商卡片
        let providers = [
            APIProvider(name: "智谱", identifier: "zhipu"),
            APIProvider(name: "OpenAI", identifier: "openai"),
            APIProvider(name: "豆包", identifier: "doubao"),
        ]
        
        for provider in providers {
            let card = ProviderCardView(provider: provider)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 110).isActive = true
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 340).isActive = true
            
            card.onSelectionChanged { [weak self] isSelected in
                if isSelected {
                    // 取消其他卡片的选择
                    for (_, otherCard) in self?.providerCards ?? [:] {
                        if otherCard.provider.identifier != provider.identifier {
                            otherCard.setSelected(false)
                        }
                    }
                }
            }
            
            contentStackView.addArrangedSubview(card)
            providerCards[provider.identifier] = card
        }
        
        // 添加伸缩空间
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(spacer)
    }
    
    private func showTimeSettingsCategory() {
        let label = NSTextField(labelWithString: "时间设置（功能开发中）")
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(label)
    }
    
    private func showClearCacheCategory() {
        let label = NSTextField(labelWithString: "清理缓存（功能开发中）")
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(label)
    }
    
    // MARK: - 保存设置
    @objc private func saveSettings() {
        // 获取选中的服务商和对应的 API Key
        guard let selectedCard = providerCards.values.first(where: { $0.isSelected }) else {
            showStatus("请选择一个 API 服务商", isError: true)
            return
        }
        
        let apiKey = selectedCard.getAPIKey()
        
        // 验证输入
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            showStatus("API Key 不能为空", isError: true)
            return
        }
        
        // 保存到本地文件
        let success = LocalKeysTool.shared.saveZhipuAPIKey(apiKey)
        
        if success {
            showStatus("保存成功", isError: false)
        } else {
            showStatus("保存失败", isError: true)
        }
    }
    
    // MARK: - 加载保存的设置
    private func loadSavedKeys() {
        if let zhipuKey = LocalKeysTool.shared.getZhipuAPIKey() {
            // 加载第一个卡片（智谱）的值
            if let zhipuCard = providerCards["zhipu"] {
                zhipuCard.setAPIKey(zhipuKey)
                zhipuCard.setSelected(true)
            }
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
