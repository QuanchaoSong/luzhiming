//
//  LeftSideBarView.swift
//  luzhiming
//
//  左侧分类侧边栏视图
//

import Cocoa

class LeftSideBarView: NSView {
	private let stackView = NSStackView()
	private var onSelect: ((Int) -> Void)?
	private var buttons: [NSButton] = []
    
	init(categories: [String], onSelect: @escaping (Int) -> Void) {
		self.onSelect = onSelect
		super.init(frame: .zero)
		setupUI(categories: categories)
	}
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI(categories: [])
	}
    
	private func setupUI(categories: [String]) {
		translatesAutoresizingMaskIntoConstraints = false
		wantsLayer = true
		layer?.backgroundColor = NSColor.separatorColor.cgColor
        
		stackView.orientation = .vertical
		stackView.spacing = 6
		stackView.distribution = .equalSpacing
		stackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stackView)
        
		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
			stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
			stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20),
		])
        
		for (index, category) in categories.enumerated() {
			let button = NSButton()
			button.title = category
			button.setButtonType(.momentaryChange)
			button.bezelStyle = .rounded
			button.font = NSFont.systemFont(ofSize: 11)
			button.translatesAutoresizingMaskIntoConstraints = false
			button.target = self
			button.action = #selector(categoryTapped(_:))
			button.tag = index
			button.heightAnchor.constraint(equalToConstant: 24).isActive = true
			stackView.addArrangedSubview(button)
			buttons.append(button)
		}
	}
    
	@objc private func categoryTapped(_ sender: NSButton) {
		onSelect?(sender.tag)
	}
    
	func setSelected(index: Int) {
		// 可选：高亮当前分类
		for (i, btn) in buttons.enumerated() {
			btn.state = (i == index) ? .on : .off
		}
	}
}
