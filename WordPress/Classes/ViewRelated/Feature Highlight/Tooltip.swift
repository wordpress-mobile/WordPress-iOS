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

    private let containerView = UIView()

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        setUpContainerView()
        setUpConstraints()
        addArrowHead()
    }

    private func setUpContainerView() {
        containerView.backgroundColor = .invertedSystem5
        containerView.layer.cornerRadius = Constants.cornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    private func setUpConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.Spacing.contentStackViewTop),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            containerView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: Constants.Spacing.contentStackViewHorizontal),
            containerView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: Constants.Spacing.contentStackViewBottom),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width - Constants.Spacing.superHorizontalMargin),
            buttonsStackView.heightAnchor.constraint(equalToConstant: Constants.Spacing.buttonStackViewHeight)
        ])
    }

    private func addArrowHead() {
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 0, y: 0))
        arrowPath.addLine(to: CGPoint(x: 9, y: -11))
        arrowPath.addQuadCurve(to: CGPoint(x: 11, y: -11), controlPoint: CGPoint(x: 10, y: -12))
        arrowPath.addLine(to: CGPoint(x: 19, y: 0))
        arrowPath.close()

        // Create a CAShapeLayer
        let shapeLayer = CAShapeLayer()

        // The Bezier path that we made needs to be converted to
        // a CGPath before it can be used on a layer.
        shapeLayer.path = arrowPath.cgPath

        // apply other properties related to the path
        shapeLayer.strokeColor = UIColor.invertedSystem5.cgColor
        shapeLayer.fillColor = UIColor.invertedSystem5.cgColor
        shapeLayer.lineWidth = 1.0

        shapeLayer.position = CGPoint(x: 20, y: 0)

        // add the new layer to our custom view
        containerView.layer.addSublayer(shapeLayer)
    }
}
