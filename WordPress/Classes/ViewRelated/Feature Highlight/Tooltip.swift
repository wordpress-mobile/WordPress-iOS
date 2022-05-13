import UIKit

final class Tooltip: UIView {
    static let arrowWidth: CGFloat = 17

    private enum Constants {
        static let leadingIconUnicode = "✨"
        static let cornerRadius: CGFloat = 4
        static let arrowTipYLength: CGFloat = 8
        static let arrowTipYControlLength: CGFloat = 9
        static let maxWidth: CGFloat = UIScreen.main.bounds.width - Spacing.superHorizontalMargin
        static let maxContentWidth = maxWidth - (Constants.Spacing.contentStackViewHorizontal * 2)


        enum Spacing {
            static let contentStackViewInterItemSpacing: CGFloat = 4
            static let buttonsStackViewInterItemSpacing: CGFloat = 16
            static let contentStackViewTop: CGFloat = 12
            static let contentStackViewBottom: CGFloat = 4
            static let contentStackViewHorizontal: CGFloat = 16
            static let superHorizontalMargin: CGFloat = 16
            static let buttonStackViewHeight: CGFloat = 40
        }

        enum Font {
            static let title = WPStyleGuide.fontForTextStyle(.body)
            static let message = WPStyleGuide.fontForTextStyle(.body)
            static let button = WPStyleGuide.fontForTextStyle(.subheadline)
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
            accessibilityLabel = title
        }
    }

    /// String for secondary label. To be used as description
    var message: String? {
        didSet {
            messageLabel.text = message
            accessibilityValue = message
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

    private lazy var titleLabel: UILabel = {
        $0.font = Constants.Font.title
        $0.textColor = .invertedLabel
        return $0
    }(UILabel())

    private lazy var messageLabel: UILabel = {
        $0.font = Constants.Font.message
        $0.textColor = .invertedSecondaryLabel
        $0.numberOfLines = 3
        return $0
    }(UILabel())

    private(set) lazy var primaryButton: UIButton = {
        $0.titleLabel?.font = Constants.Font.button
        $0.setTitleColor(.primaryLight, for: .normal)
        return $0
    }(UIButton())

    private(set) lazy var secondaryButton: UIButton = {
        $0.titleLabel?.font = Constants.Font.button
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
    private var containerTopConstraint: NSLayoutConstraint?
    private var containerBottomConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Adds a tooltip  Arrow Head at the given X Offset and either to the top or the bottom.
    /// - Parameters:
    ///   - offsetX: The offset on which the arrow will be placed. The value must be above 0 and below maxX of the view.
    ///   - arrowPosition: Arrow will be placed either on `.top`, pointed up, or `.bottom`, pointed down.
    func addArrowHead(toXPosition offsetX: CGFloat, arrowPosition: ArrowPosition) {
        let arrowTipY: CGFloat
        let arrowTipYControl: CGFloat
        let offsetY: CGFloat

        switch arrowPosition {
        case .top:
            offsetY = 0
            arrowTipY = Constants.arrowTipYLength * -1
            arrowTipYControl = Constants.arrowTipYControlLength * -1
            containerTopConstraint?.constant = Constants.arrowTipYControlLength
            containerBottomConstraint?.constant = 0
        case .bottom:
            offsetY = Self.height(withTitle: titleLabel.text, message: message)
            arrowTipY = Constants.arrowTipYLength
            arrowTipYControl = Constants.arrowTipYControlLength
            containerTopConstraint?.constant = 0
            containerBottomConstraint?.constant = Constants.arrowTipYControlLength
        }

        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 0, y: 0))
        let arrowOriginX = (Self.arrowWidth/2 - 1)
        // In order to have a full width of `arrowWidth`, first draw the left side of the triangle until arrowOriginX.
        arrowPath.addLine(to: CGPoint(x: arrowOriginX, y: arrowTipY))
        // Add curve until `arrowWidth/2 + 1` (2 points of curve for a rounded arrow tip).
        arrowPath.addQuadCurve(
            to: CGPoint(x: arrowOriginX + 2, y: arrowTipY),
            controlPoint: CGPoint(x: Self.arrowWidth/2, y: arrowTipYControl)
        )
        // Draw down to 20.
        arrowPath.addLine(to: CGPoint(x: Self.arrowWidth, y: 0))
        arrowPath.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrowPath.cgPath
        shapeLayer.strokeColor = UIColor.invertedSystem5.cgColor
        shapeLayer.fillColor = UIColor.invertedSystem5.cgColor
        shapeLayer.lineWidth = 1.0

        shapeLayer.position = CGPoint(x: offsetX - Self.arrowWidth/2, y: offsetY)

        containerView.layer.addSublayer(shapeLayer)
    }

    func size() -> CGSize {
        CGSize(
            width: Self.width(
                title: titleLabel.text,
                message: message,
                primaryButtonTitle: primaryButton.titleLabel?.text,
                secondaryButtonTitle: secondaryButton.titleLabel?.text
            ),
            height: Self.height(
                withTitle: title,
                message: message
            )
        )
    }

    private func commonInit() {
        backgroundColor = .clear

        setUpContainerView()
        setUpConstraints()
        addShadow()
        isAccessibilityElement = true
    }

    private func setUpContainerView() {
        containerView.backgroundColor = .invertedSystem5
        containerView.layer.cornerRadius = Constants.cornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        containerTopConstraint = containerView.topAnchor.constraint(equalTo: topAnchor)
        containerBottomConstraint = bottomAnchor.constraint(equalTo: containerView.bottomAnchor)

        NSLayoutConstraint.activate([
            containerTopConstraint!,
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            containerBottomConstraint!
        ])
    }

    private func setUpConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: Constants.Spacing.contentStackViewTop
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: Constants.Spacing.contentStackViewHorizontal
            ),
            containerView.trailingAnchor.constraint(
                equalTo: contentStackView.trailingAnchor,
                constant: Constants.Spacing.contentStackViewHorizontal
            ),
            containerView.bottomAnchor.constraint(
                equalTo: contentStackView.bottomAnchor,
                constant: Constants.Spacing.contentStackViewBottom
            ),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maxWidth),
            buttonsStackView.heightAnchor.constraint(equalToConstant: Constants.Spacing.buttonStackViewHeight)
        ])
    }

    private func addShadow() {
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.5
    }

    private static func height(
        withTitle title: String?,
        message: String?
    ) -> CGFloat {
        var totalHeight: CGFloat = 0

        totalHeight += Constants.Spacing.contentStackViewTop

        if let title = title {
            totalHeight += title.height(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.title)
        }

        totalHeight += Constants.Spacing.contentStackViewInterItemSpacing

        if let message = message {
            totalHeight += message.height(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.message)
        }

        totalHeight += Constants.Spacing.buttonStackViewHeight
        totalHeight += Constants.Spacing.contentStackViewBottom

        return totalHeight
    }

    private static func width(
        title: String?,
        message: String?,
        primaryButtonTitle: String?,
        secondaryButtonTitle: String?
    ) -> CGFloat {

        let titleWidth: CGFloat
        if let title = title {
            titleWidth = title.width(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.title)
        } else {
            titleWidth = 0
        }

        let messageWidth: CGFloat
        if let message = message {
            messageWidth = message.width(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.message)
        } else {
            messageWidth = 0
        }

        var buttonsWidth: CGFloat = 0
        if let primaryButtonTitle = primaryButtonTitle {
            buttonsWidth += primaryButtonTitle.width(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.button)
        }

        if let secondaryButtonTitle = secondaryButtonTitle {
            buttonsWidth += secondaryButtonTitle.width(withMaxWidth: Constants.maxContentWidth, font: Constants.Font.button) + Constants.Spacing.buttonsStackViewInterItemSpacing
        }

        return max(max(titleWidth, messageWidth), buttonsWidth) + Constants.Spacing.contentStackViewHorizontal * 2
    }
}

private extension String {
    private func size(withMaxWidth maxWidth: CGFloat, font: UIFont) -> CGRect {
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )

        return boundingBox
    }

    func height(withMaxWidth maxWidth: CGFloat, font: UIFont) -> CGFloat {
        ceil(size(withMaxWidth: maxWidth, font: font).height)
    }

    func width(withMaxWidth maxWidth: CGFloat, font: UIFont) -> CGFloat {
        ceil(size(withMaxWidth: maxWidth, font: font).width)
    }
}
