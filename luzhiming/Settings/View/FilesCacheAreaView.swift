//
//  FilesCacheAreaView.swift
//  luzhiming
//
//  缓存清理区域
//

import Cocoa

class FilesCacheAreaView: NSView {
	private let stackView = NSStackView()
	private let maxFilesField = NSTextField()
	private let autoCleanCheckbox = NSButton()
	private let saveButton = NSButton()
	private let cleanNowButton = NSButton()
	private let statusLabel = NSTextField()
	private let infoLabel = NSTextField()
    
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupUI()
		loadCurrentSettings()
		updateCacheInfo()
	}
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
		loadCurrentSettings()
		updateCacheInfo()
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
		let titleLabel = NSTextField(labelWithString: "录音缓存管理")
		titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
		titleLabel.isBezeled = false
		titleLabel.drawsBackground = false
		titleLabel.isEditable = false
		stackView.addArrangedSubview(titleLabel)
		
		// 缓存信息
		infoLabel.font = NSFont.systemFont(ofSize: 11)
		infoLabel.textColor = NSColor.secondaryLabelColor
		infoLabel.isBezeled = false
		infoLabel.drawsBackground = false
		infoLabel.isEditable = false
		stackView.addArrangedSubview(infoLabel)
		
		// 最大文件数
		let maxFilesRow = createSettingRow(
			label: "最多保留录音文件数:",
			field: maxFilesField,
			placeholder: "50"
		)
		stackView.addArrangedSubview(maxFilesRow)
		
		// 自动清理
		let autoCleanRow = NSView()
		autoCleanRow.translatesAutoresizingMaskIntoConstraints = false
		
		let autoLabel = NSTextField(labelWithString: "自动清理旧录音:")
		autoLabel.font = NSFont.systemFont(ofSize: 12)
		autoLabel.translatesAutoresizingMaskIntoConstraints = false
		autoCleanRow.addSubview(autoLabel)
		
		autoCleanCheckbox.setButtonType(.switch)
		autoCleanCheckbox.title = ""
		autoCleanCheckbox.translatesAutoresizingMaskIntoConstraints = false
		autoCleanRow.addSubview(autoCleanCheckbox)
		
		NSLayoutConstraint.activate([
			autoLabel.leadingAnchor.constraint(equalTo: autoCleanRow.leadingAnchor),
			autoLabel.centerYAnchor.constraint(equalTo: autoCleanRow.centerYAnchor),
			autoLabel.widthAnchor.constraint(equalToConstant: 160),
			
			autoCleanCheckbox.leadingAnchor.constraint(equalTo: autoLabel.trailingAnchor, constant: 8),
			autoCleanCheckbox.centerYAnchor.constraint(equalTo: autoCleanRow.centerYAnchor),
			
			autoCleanRow.heightAnchor.constraint(equalToConstant: 24),
		])
		
		stackView.addArrangedSubview(autoCleanRow)
		
		// 按钮行
		let buttonRow = NSView()
		buttonRow.translatesAutoresizingMaskIntoConstraints = false
		
		saveButton.title = "保存设置"
		saveButton.setButtonType(.momentaryPushIn)
		saveButton.bezelStyle = .rounded
		saveButton.target = self
		saveButton.action = #selector(saveSettings)
		saveButton.translatesAutoresizingMaskIntoConstraints = false
		buttonRow.addSubview(saveButton)
		
		cleanNowButton.title = "立即清理"
		cleanNowButton.setButtonType(.momentaryPushIn)
		cleanNowButton.bezelStyle = .rounded
		cleanNowButton.target = self
		cleanNowButton.action = #selector(cleanNow)
		cleanNowButton.translatesAutoresizingMaskIntoConstraints = false
		buttonRow.addSubview(cleanNowButton)
		
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
			
			cleanNowButton.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 12),
			cleanNowButton.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
			cleanNowButton.widthAnchor.constraint(equalToConstant: 80),
			
			statusLabel.leadingAnchor.constraint(equalTo: cleanNowButton.trailingAnchor, constant: 12),
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
		maxFilesField.intValue = Int32(settings.maxAudioRecordings)
		autoCleanCheckbox.state = settings.autoCleanOldRecordings ? .on : .off
	}
	
	private func updateCacheInfo() {
		let recordingsDir = SettingsInfo.shared.getAudioRecordingsDirectory()
		let fileManager = FileManager.default
		
		do {
			let files = try fileManager.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
			let totalSize = files.reduce(0) { sum, url in
				let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
				return sum + size
			}
			let sizeMB = Double(totalSize) / 1024.0 / 1024.0
			infoLabel.stringValue = String(format: "当前缓存: %d 个文件，共 %.2f MB", files.count, sizeMB)
		} catch {
			infoLabel.stringValue = "缓存目录: \(recordingsDir.path)"
		}
	}
	
	@objc private func saveSettings() {
		guard let maxFiles = Int(maxFilesField.stringValue), maxFiles > 0 else {
			showStatus("请输入有效的文件数", isError: true)
			return
		}
		
		SettingsInfo.shared.maxAudioRecordings = maxFiles
		SettingsInfo.shared.autoCleanOldRecordings = (autoCleanCheckbox.state == .on)
		
		showStatus("保存成功", isError: false)
	}
	
	@objc private func cleanNow() {
		SettingsInfo.shared.cleanupOldRecordings()
		updateCacheInfo()
		showStatus("清理完成", isError: false)
	}
	
	private func showStatus(_ message: String, isError: Bool) {
		statusLabel.stringValue = message
		statusLabel.textColor = isError ? NSColor.red : NSColor.green
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
			self.statusLabel.stringValue = ""
		}
	}
}
