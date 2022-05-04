import UIKit

final class Tooltip: UIView {
    private enum Constants {
        static let leadingIconUnicode = "✨"
        static let cornerRadius: CGFloat = 4

        enum Spacing {
            static let contentStackViewInterItemSpacing: CGFloat = 4
            static let buttonsStackViewInterItemSpacing: CGFloat = 16
            static let contentStackViewTop: CGFloat = 12
            static let contentStackViewBottom: CGFloat = 4
            static let contentStackViewHorizontal: CGFloat = 16
            static let superHorizontalMargin: CGFloat = 16
            static let buttonStackViewHeight: CGFloat = 40
        }
    }

    enum ButtonAlignment {
        case left
        case right
    }

    enum ArrowPosition {
        case top
        case bottom
    }

    /// Determines whether a leading icon for the title, should be placed or not.
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

    /// String for primary label. To be used as the title.
    /// If `shouldPrefixLeadingIcon` is `true`, a leading icon will be prefixed.
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

    /// String for secondary label. To be used as description
    var message: String? {
        didSet {
            messageLabel.text = message
        }
    }

    /// Determines the alignment for the action buttons.
    var buttonAlignment: ButtonAlignment = .left {
        didSet {
            buttonsStackView.removeAllSubviews()
            switch buttonAlignment {
            case .left:
                buttonsStackView.addArrangedSubviews([primaryButton, secondaryButton, UIView()])
            case .right:
                buttonsStackView.addArrangedSubviews([UIView(), primaryButton, secondaryButton])
            }
        }
    }

    var arrowPosition: ArrowPosition = .bottom

    private lazy var titleLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.textColor = .invertedLabel
        return $0
    }(UILabel())

    private lazy var messageLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.textColor = .invertedSecondaryLabel
        $0.numberOfLines = 3
        return $0
    }(UILabel())

    private(set) lazy var primaryButton: UIButton = {
        $0.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        $0.setTitleColor(.primaryLight, for: .normal)
        return $0
    }(UIButton())

    private(set) lazy var secondaryButton: UIButton = {
        $0.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        $0.setTitleColor(.primaryLight, for: .normal)
        return $0
    }(UIButton())

    private lazy var contentStackView: UIStackView = {
        $0.addArrangedSubviews([titleLabel, messageLabel, buttonsStackView])
        $0.spacing = Constants.Spacing.contentStackViewInterItemSpacing
        $0.axis = .vertical
        return $0
    }(UIStackView())

    private lazy var buttonsStackView: UIStackView = {
        $0.addArrangedSubviews([primaryButton, secondaryButton, UIView()])
        $0.spacing = Constants.Spacing.buttonsStackViewInterItemSpacing
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
        translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.Spacing.contentStackViewTop),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: Constants.Spacing.contentStackViewBottom),
            widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width - Constants.Spacing.superHorizontalMargin),
            buttonsStackView.heightAnchor.constraint(equalToConstant: Constants.Spacing.buttonStackViewHeight)
        ])
    }
}
