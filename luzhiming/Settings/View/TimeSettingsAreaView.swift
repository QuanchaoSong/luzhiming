//
//  TimeSettingsAreaView.swift
//  luzhiming
//
//  时间设置区域
//

import Cocoa

class TimeSettingsAreaView: NSView {
	private let stackView = NSStackView()
	private let minDurationField = NSTextField()
	private let maxDurationField = NSTextField()
	private let saveButton = NSButton()
	private let statusLabel = NSTextField()
    
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupUI()
		loadCurrentSettings()
	}
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
		loadCurrentSettings()
	}
    
	private func setupUI() {
		translatesAutoresizingMaskIntoConstraints = false
		
		// 垂直堆栈
		stackView.orientation = .vertical
		stackView.spacing = 16
		stackView.distribution = .fill
		stackView.alignment = .leading
		stackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stackView)
		
		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			stackView.topAnchor.constraint(equalTo: topAnchor),
			stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
		
		// 标题
		let titleLabel = NSTextField(labelWithString: "录音时长设置")
		titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
		titleLabel.isBezeled = false
		titleLabel.drawsBackground = false
		titleLabel.isEditable = false
		stackView.addArrangedSubview(titleLabel)
		
		// 最短录音时长
		let minRow = createSettingRow(
			label: "最短录音时长（秒）:",
			field: minDurationField,
			placeholder: "1.0"
		)
		stackView.addArrangedSubview(minRow)
		
		// 最长录音时长
		let maxRow = createSettingRow(
			label: "最长录音时长（秒）:",
			field: maxDurationField,
			placeholder: "60.0"
		)
		stackView.addArrangedSubview(maxRow)
		
		// 保存按钮
		let buttonRow = NSView()
		buttonRow.translatesAutoresizingMaskIntoConstraints = false
		
		saveButton.title = "保存"
		saveButton.setButtonType(.momentaryPushIn)
		saveButton.bezelStyle = .rounded
		saveButton.target = self
		saveButton.action = #selector(saveSettings)
		saveButton.translatesAutoresizingMaskIntoConstraints = false
		buttonRow.addSubview(saveButton)
		
		statusLabel.isBezeled = false
		statusLabel.drawsBackground = false
		statusLabel.isEditable = false
		statusLabel.font = NSFont.systemFont(ofSize: 11)
		statusLabel.translatesAutoresizingMaskIntoConstraints = false
		buttonRow.addSubview(statusLabel)
		
		NSLayoutConstraint.activate([
			saveButton.leadingAnchor.constraint(equalTo: buttonRow.leadingAnchor),
			saveButton.topAnchor.constraint(equalTo: buttonRow.topAnchor),
			saveButton.bottomAnchor.constraint(equalTo: buttonRow.bottomAnchor),
			saveButton.widthAnchor.constraint(equalToConstant: 80),
			
			statusLabel.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 12),
			statusLabel.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
			
			buttonRow.heightAnchor.constraint(equalToConstant: 30),
		])
		
		stackView.addArrangedSubview(buttonRow)
	}
	
	private func createSettingRow(label: String, field: NSTextField, placeholder: String) -> NSView {
		let row = NSView()
		row.translatesAutoresizingMaskIntoConstraints = false
		
		let labelView = NSTextField(labelWithString: label)
		labelView.font = NSFont.systemFont(ofSize: 12)
		labelView.translatesAutoresizingMaskIntoConstraints = false
		row.addSubview(labelView)
		
		field.placeholderString = placeholder
		field.translatesAutoresizingMaskIntoConstraints = false
		row.addSubview(field)
		
		NSLayoutConstraint.activate([
			labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
			labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
			labelView.widthAnchor.constraint(equalToConstant: 160),
			
			field.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
			field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
			field.widthAnchor.constraint(equalToConstant: 120),
			
			row.heightAnchor.constraint(equalToConstant: 24),
		])
		
		return row
	}
	
	private func loadCurrentSettings() {
		let settings = SettingsInfo.shared
		minDurationField.stringValue = String(format: "%.1f", settings.minRecordingDuration)
		maxDurationField.stringValue = String(format: "%.1f", settings.maxRecordingDuration)
	}
	
	@objc private func saveSettings() {
		guard let minValue = Double(minDurationField.stringValue),
		      let maxValue = Double(maxDurationField.stringValue) else {
			showStatus("请输入有效的数字", isError: true)
			return
		}
		
		guard minValue > 0 && maxValue > 0 else {
			showStatus("时长必须大于 0", isError: true)
			return
		}
		
		guard minValue <= maxValue else {
			showStatus("最短时长不能大于最长时长", isError: true)
			return
		}
		
		SettingsInfo.shared.minRecordingDuration = minValue
		SettingsInfo.shared.maxRecordingDuration = maxValue
		
		showStatus("保存成功", isError: false)
	}
	
	private func showStatus(_ message: String, isError: Bool) {
		statusLabel.stringValue = message
		statusLabel.textColor = isError ? NSColor.red : NSColor.green
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
			self.statusLabel.stringValue = ""
		}
	}
}
