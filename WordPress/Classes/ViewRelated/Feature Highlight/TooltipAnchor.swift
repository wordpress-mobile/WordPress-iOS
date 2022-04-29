import UIKit

final class TooltipAnchor: UIControl {
    private enum Constants {
        static let horizontalMarginToBounds: CGFloat = 16
        static let verticalMarginToBounds: CGFloat = 9
        static let stackViewSpacing: CGFloat = 4
        static let viewHeight: CGFloat = 40
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    private lazy var titleLabel: UILabel = {
        $0.textColor = .invertedLabel
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        return $0
    }(UILabel())

    private lazy var highlightLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.text = "✨"
        return $0
    }(UILabel())

    private lazy var stackView: UIStackView = {
        $0.addArrangedSubviews([highlightLabel, titleLabel])
        $0.spacing = Constants.stackViewSpacing
        return $0
    }(UIStackView())

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setUpViewHierarchy()
        configureUI()
    }

    private func setUpViewHierarchy() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.viewHeight),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalMarginToBounds),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalMarginToBounds),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Constants.horizontalMarginToBounds),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.verticalMarginToBounds)
        ])
    }

    private func configureUI() {
        backgroundColor = .invertedSystem5
        layer.cornerRadius = Constants.viewHeight / 2
    }
}
