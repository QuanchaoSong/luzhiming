//
//  ProviderCardView.swift
//  luzhiming
//
//  封装单个厂商卡片视图
//

import Cocoa

class ProviderCardView: NSView {
	let providerName: String
	let providerID: String
	private(set) var isSelected: Bool = false
    
	private let titleLabel = NSTextField()
	private let apiKeyField = NSTextField()
	private let selectedCheckbox = NSButton()
	private let saveButton = NSButton()
    
	private var onSelectionChanged: ((Bool) -> Void)?
	private var onSave: ((String, String) -> Void)?
    
	init(name: String, id: String) {
		self.providerName = name
		self.providerID = id
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
		layer?.backgroundColor = NSColor.white.cgColor
        
	// 标题
	titleLabel.stringValue = providerName
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
	apiKeyField.placeholderString = "输入 \(providerName) API Key"
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
        
		// 保存按钮（右下角）
		saveButton.title = "保存"
		saveButton.setButtonType(.momentaryPushIn)
		saveButton.bezelStyle = .rounded
		saveButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
		saveButton.translatesAutoresizingMaskIntoConstraints = false
		saveButton.target = self
		saveButton.action = #selector(saveButtonTapped)
		addSubview(saveButton)
        
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
            
			// 保存按钮在右下角
			saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
			saveButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
			saveButton.widthAnchor.constraint(equalToConstant: 60),
			saveButton.heightAnchor.constraint(equalToConstant: 22),
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
    
	func onSaveTapped(_ callback: @escaping (String, String) -> Void) {
		self.onSave = callback
	}
    
	@objc private func checkboxToggled() {
		isSelected = selectedCheckbox.state == .on
		updateCardAppearance()
		onSelectionChanged?(isSelected)
	}
    
	private func updateCardAppearance() {
		if isSelected {
			let lightGray = NSColor(calibratedWhite: 0.90, alpha: 1.0)
			layer?.backgroundColor = lightGray.cgColor
			layer?.borderColor = NSColor.separatorColor.cgColor
			titleLabel.textColor = NSColor.labelColor
			apiKeyField.textColor = NSColor.labelColor
			selectedCheckbox.attributedTitle = NSAttributedString(
				string: "使用此服务",
				attributes: [.foregroundColor: NSColor.labelColor]
			)
		} else {
			layer?.backgroundColor = NSColor.white.cgColor
			layer?.borderColor = NSColor.separatorColor.cgColor
			titleLabel.textColor = NSColor.labelColor
			apiKeyField.textColor = NSColor.labelColor
			selectedCheckbox.attributedTitle = NSAttributedString(
				string: "使用此服务",
				attributes: [.foregroundColor: NSColor.labelColor]
			)
		}
	}
    
	@objc private func saveButtonTapped() {
		onSave?(providerID, getAPIKey())
	}
}

