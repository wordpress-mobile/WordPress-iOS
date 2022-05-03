import UIKit

final class Tooltip: UIView {
    private enum Constants {
        static let leadingIconUnicode = "✨"
        static let cornerRadius: CGFloat = 4

        enum Spacing {
            static let contentStackView: CGFloat = 4
            static let buttonsStackView: CGFloat = 16
            static let contentStackViewTop: CGFloat = 12
            static let contentStackViewBottom: CGFloat = 12
            static let contentStackViewHorizontal: CGFloat = 16
        }
    }

    var shouldPrefixLeadingIcon: Bool = true {
        didSet {
            guard let title = title else { return }

            Self.updateTitleLabel(
                titleLabel,
                with: title,
                shouldPrefixLeadingIcon: shouldPrefixLeadingIcon
            )
        }
    }

    var title: String? {
        didSet {
            guard let title = title else {
                titleLabel.text = nil
                return
            }

            Self.updateTitleLabel(
                titleLabel,
                with: title,
                shouldPrefixLeadingIcon: shouldPrefixLeadingIcon
            )
        }
    }

    var message: String? {
        didSet {
            messageLabel.text = message
        }
    }

    private lazy var titleLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.textColor = .invertedLabel
        return $0
    }(UILabel())

    private lazy var messageLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 3
        return $0
    }(UILabel())

    private(set) lazy var primaryButton: UIButton = {
        $0.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        return $0
    }(UIButton())

    private(set) lazy var secondaryButton: UIButton = {
        $0.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        return $0
    }(UIButton())

    private lazy var contentStackView: UIStackView = {
        $0.addArrangedSubviews([titleLabel, messageLabel, buttonsStackView])
        $0.spacing = Constants.Spacing.contentStackView
        $0.axis = .vertical
        return $0
    }(UIStackView())

    private lazy var buttonsStackView: UIStackView = {
        $0.addArrangedSubviews([primaryButton, secondaryButton])
        $0.spacing = Constants.Spacing.buttonsStackView
        return $0
    }(UIStackView())

    private static func updateTitleLabel(
        _ titleLabel: UILabel,
        with text: String,
        shouldPrefixLeadingIcon: Bool) {

        if shouldPrefixLeadingIcon {
            titleLabel.text = Constants.leadingIconUnicode + " " + text
        } else {
            titleLabel.text = text
        }
    }

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .invertedSystem5
        layer.cornerRadius = Constants.cornerRadius

        setUpConstraints()
    }

    private func setUpConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.Spacing.contentStackViewTop),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: Constants.Spacing.contentStackViewBottom)
        ])
    }
}
