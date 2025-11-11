//
//  TimeSettingsAreaView.swift
//  luzhiming
//
//  时间设置区域占位视图
//

import Cocoa

class TimeSettingsAreaView: NSView {
	private let label = NSTextField(labelWithString: "时间设置（功能开发中）")
    
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupUI()
	}
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
	}
    
	private func setupUI() {
		translatesAutoresizingMaskIntoConstraints = false
		label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)
        
		NSLayoutConstraint.activate([
			label.topAnchor.constraint(equalTo: topAnchor),
			label.leadingAnchor.constraint(equalTo: leadingAnchor),
		])
	}
}
