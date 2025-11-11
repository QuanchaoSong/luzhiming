//
//  SettingsViewController.swift
//  luzhiming
//

import Cocoa
import Foundation
// 需要访问定义在其他文件中的 APIProvider 和 ProviderCardView

// 引入模型与视图组件
// (若使用 SwiftPM / 模块化，可改为 import 对应模块)

// ProviderCardView 和 APIProvider 已拆分至 Settings/View 与 Settings/Model 目录

class SettingsViewController: NSViewController {
    
    // 侧边栏 & 内容区域
    private var sidebarView: LeftSideBarView!
    private let contentView = NSView()
    private let contentScrollView = NSScrollView()
    private let contentStackView = NSStackView()
    
    // 状态标签
    private let statusLabel = NSTextField()
    
    // 厂商卡片
    private var providerCards: [String: ProviderCardView] = [:]
    
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
        // 默认渲染 API Keys 分类
        handleCategorySelection(index: 0)
    }
    
    private func setupUI() {
        // 主容器 - 横向分割
        let mainContainer = NSView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        // ===== 侧边栏 (封装) =====
        sidebarView = LeftSideBarView(categories: categories) { [weak self] index in
            self?.handleCategorySelection(index: index)
        }
        mainContainer.addSubview(sidebarView)
        NSLayoutConstraint.activate([
            sidebarView.widthAnchor.constraint(equalToConstant: 150),
            sidebarView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            sidebarView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
        ])
        
        // ===== 内容区域设置 =====
    contentView.translatesAutoresizingMaskIntoConstraints = false
    // 设为白色背景
    contentView.wantsLayer = true
    contentView.layer?.backgroundColor = NSColor.white.cgColor
    mainContainer.addSubview(contentView)
        
        // 滚动视图
    contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.hasVerticalScroller = true
        contentScrollView.hasHorizontalScroller = false
        contentScrollView.autohidesScrollers = true
    contentScrollView.drawsBackground = true
    contentScrollView.backgroundColor = NSColor.white
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
        
        // ===== 状态标签 =====
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.isEditable = false
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
        ])
        
        // 主容器约束
        NSLayoutConstraint.activate([
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
    // 初始化 API Keys 分类（通过统一渲染入口）
    renderCurrentCategory()
    }
    
    private func handleCategorySelection(index: Int) {
        guard index < categories.count else { return }
        currentCategory = categories[index]
        sidebarView.setSelected(index: index)
        
        // 清空内容
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        providerCards.removeAll()
        statusLabel.stringValue = ""
        
        renderCurrentCategory()
    }
    
    private func renderCurrentCategory() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        providerCards.removeAll()
        switch currentCategory {
        case "API Keys":
            let apiView = ApiKeysAreaView { [weak self] providerId, key in
                self?.saveAPIKey(for: providerId, key: key)
            }
            contentStackView.addArrangedSubview(apiView)
            // 保存引用供后续设置 keys & selection
            // 从内部取卡片引用（直接访问不暴露，选择逻辑现在在 ApiKeysAreaView 内部实现）
            // 加载已保存 key
            loadSavedKeys(into: apiView)
        case "时间设置":
            let timeView = TimeSettingsAreaView()
            contentStackView.addArrangedSubview(timeView)
        case "清理缓存":
            let cacheView = FilesCacheAreaView()
            contentStackView.addArrangedSubview(cacheView)
        default:
            break
        }
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(spacer)
    }
    
    // MARK: - 保存设置（按卡片）
    private func saveAPIKey(for providerId: String, key: String) {
        // 验证输入
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showStatus("API Key 不能为空", isError: true)
            return
        }
        
        var success = false
        switch providerId {
        case "zhipu":
            success = LocalKeysTool.shared.saveZhipuAPIKey(trimmed)
        case "openai":
            success = saveKeyToFile(trimmed, filename: "openai_api_key")
        case "doubao":
            success = saveKeyToFile(trimmed, filename: "doubao_api_key")
        default:
            success = false
        }
        
        if success {
            showStatus("保存成功", isError: false)
        } else {
            showStatus("保存失败", isError: true)
        }
    }
    
    // MARK: - 加载保存的设置
    private func loadSavedKeys(into apiView: ApiKeysAreaView) {
        // 从 SettingsInfo 获取当前选中的服务商
        let currentProvider = SettingsInfo.shared.apiKeyProvider
        let providerId = mapProviderToId(currentProvider)
        
        // 加载各厂商的 API Keys
        if let zhipuKey = LocalKeysTool.shared.getZhipuAPIKey() {
            apiView.setKey(zhipuKey, for: "zhipu")
        }
        if let openaiKey = loadKeyFromFile(filename: "openai_api_key") {
            apiView.setKey(openaiKey, for: "openai")
        }
        if let doubaoKey = loadKeyFromFile(filename: "doubao_api_key") {
            apiView.setKey(doubaoKey, for: "doubao")
        }
        
        // 设置当前选中的服务商
        apiView.setSelectedProvider(providerId)
    }
    
    // MARK: - Helper
    private func mapProviderToId(_ provider: ApiKeyProvider) -> String {
        switch provider {
        case .zhipu: return "zhipu"
        case .openai: return "openai"
        case .doubao: return "doubao"
        }
    }
    
    // MARK: - 文件读写（本地辅助）
    private func loadKeyFromFile(filename: String) -> String? {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let dir = homeDir.appendingPathComponent(".luzhiming").appendingPathComponent("key_files")
        let fileURL = dir.appendingPathComponent(filename)
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            return nil
        }
    }
    
    private func saveKeyToFile(_ key: String, filename: String) -> Bool {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let dir = homeDir.appendingPathComponent(".luzhiming").appendingPathComponent("key_files")
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return false
            }
        }
        let fileURL = dir.appendingPathComponent(filename)
        do {
            try key.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
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
