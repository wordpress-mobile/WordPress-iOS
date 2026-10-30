import UIKit
import WordPressUI

class TextWithAccessoryButtonCell: WPReusableTableViewCell {
    var buttonText: String? {
        get {
            button.configuration?.title
        }
        set {
            button.configuration?.title = newValue
        }
    }

    private let mainLabel: UILabel = {
        let label = makeLabel(fontSize: 16)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.textColor = .secondaryLabel
        return label
    }()
    private let secondaryLabel: UILabel = {
        let label = makeLabel(fontSize: 14)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        label.textColor = .secondaryLabel
        return label
    }()
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()

    var onButtonTap: (() -> Void)?

    public var mainLabelText: String? {
        didSet {
            mainLabel.text = mainLabelText
        }
    }

    public var secondaryLabelText: String? {
        didSet {
            let hidden = secondaryLabelText?.nonEmptyString == nil

            secondaryLabel.isHidden = hidden
            secondaryLabel.text = secondaryLabelText
        }
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
        initialSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        button.setActivityIndicatorVisible(false)
    }

    private static func makeLabel(fontSize: CGFloat) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.backgroundColor = nil
        label.contentMode = .left
        label.textAlignment = .natural
        label.font = .systemFont(ofSize: fontSize)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        return label
    }

    private func setupSubviews() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let stackView = UIStackView(arrangedSubviews: [mainLabel, secondaryLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.isBaselineRelativeArrangement = true

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        addSubview(stackView)
        addSubview(button)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 12),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
}

private extension TextWithAccessoryButtonCell {
    func initialSetup() {
        button.configureAsPrimaryNUXButton()
    }

    @objc func buttonTapped(_ button: UIButton) {
        onButtonTap?()
    }
}
