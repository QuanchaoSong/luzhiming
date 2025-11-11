//
//  ApiKeysAreaView.swift
//  luzhiming
//
//  API Keys 配置区域：包含多个 ProviderCardView
//

import Cocoa

class ApiKeysAreaView: NSView {
	private let stackView = NSStackView()
	private var providerCards: [String: ProviderCardView] = [:]
	private var saveHandler: ((String, String) -> Void)?
    
	init(saveHandler: @escaping (String, String) -> Void) {
		self.saveHandler = saveHandler
		super.init(frame: .zero)
		setupUI()
	}
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
	}
    
	private func setupUI() {
		translatesAutoresizingMaskIntoConstraints = false
        
		// 标题
		let titleLabel = NSTextField(labelWithString: "选择 API 服务商")
		titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
		titleLabel.isBezeled = false
		titleLabel.drawsBackground = false
		titleLabel.isEditable = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
		// 垂直堆栈
		stackView.orientation = .vertical
		stackView.spacing = 10
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
        
		stackView.addArrangedSubview(titleLabel)
		titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
		// 创建厂商卡片
		let providers: [(String, String)] = [
			("智谱", "zhipu"),
			("OpenAI", "openai"),
			("豆包", "doubao"),
		]
        
		for p in providers {
			let card = ProviderCardView(name: p.0, id: p.1)
			card.translatesAutoresizingMaskIntoConstraints = false
			card.heightAnchor.constraint(equalToConstant: 110).isActive = true
			card.widthAnchor.constraint(greaterThanOrEqualToConstant: 340).isActive = true
            
			card.onSelectionChanged { [weak self] isSelected in
				guard let self = self, isSelected else { return }
				for (id, other) in self.providerCards where id != p.1 {
					other.setSelected(false)
				}
			}
            
			card.onSaveTapped { [weak self] providerId, apiKey in
				self?.saveHandler?(providerId, apiKey)
			}
            
			stackView.addArrangedSubview(card)
			providerCards[p.1] = card
		}
        
		// 伸缩空间
		let spacer = NSView()
		spacer.translatesAutoresizingMaskIntoConstraints = false
		stackView.addArrangedSubview(spacer)
	}
    
	// 外部控制：设置 key
	func setKey(_ key: String, for providerId: String) {
		providerCards[providerId]?.setAPIKey(key)
	}
    
	// 外部控制：设置选中
	func setSelectedProvider(_ providerId: String) {
		for (id, card) in providerCards {
			card.setSelected(id == providerId)
		}
	}
}
