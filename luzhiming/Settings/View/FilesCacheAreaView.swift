//
//  FilesCacheAreaView.swift
//  luzhiming
//
//  缓存清理区域占位视图
//

import Cocoa

class FilesCacheAreaView: NSView {
	private let label = NSTextField(labelWithString: "清理缓存（功能开发中）")
    
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
