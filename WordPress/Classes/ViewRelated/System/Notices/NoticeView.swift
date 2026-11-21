import UIKit
import WordPressUI
import DesignSystem

class NoticeView: UIView {
    internal let contentStackView = UIStackView()

    /// Liquid Glass on iOS 26 and later, a system material on earlier versions.
    internal let backgroundView = UIVisualEffectView(effect: Appearance.makeBackgroundEffect())
    internal let actionBackgroundView = UIView()
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    /// Container for the icon and the labels
    private let headerStackView = UIStackView()

    /// Container for the title and content labels
    private let labelStackView = UIStackView()
    internal let titleLabel = UILabel()
    internal let messageLabel = UILabel()
    private let iconView = UIImageView()

    private let actionButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private lazy var nextArrowImageView: UIImageView = {
        configureNextArrow()
    }()

    internal let notice: Notice
    internal var dualButtonsStackView: UIStackView?

    var dismissHandler: (() -> Void)?

    required init(notice: Notice) {
        self.notice = notice

        super.init(frame: .zero)

        configure()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _: UITraitCollection) in
            self.preferredContentSizeDidChange()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func configureGestureRecognizer() {
        switch notice.style.dismissGesture {
        case .tap:
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelButtonTapped))
            addGestureRecognizer(tapRecognizer)
        case .none:
            ()
        }
    }

    /// configure the NoticeView for display
    internal func configure() {
        configureBackgroundViews()
        configureShadow()
        configureContentStackView()
        configureGestureRecognizer()
        configureHeader()
        configureForNotice()

        if notice.actionTitle != nil && notice.cancelTitle != nil {
            configureDualButtons()
        } else if notice.actionTitle != nil && notice.style.showNextArrow {
            configureActionButtonWithArrow()
        } else if notice.actionTitle != nil {
            configureActionButton()
        }

        if notice.style.isDismissable {
            configureDismissRecognizers()
        }

        configureForAccessibility()

        // The trait change handler only runs on a change, so apply the current text size once here.
        preferredContentSizeDidChange()
    }

    private func configureBackgroundViews() {
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)

        backgroundView.layer.cornerCurve = .continuous
        backgroundView.clipsToBounds = true
    }

    internal func configureShadow() {
        // Liquid Glass draws its own shadow.
        guard !Appearance.usesGlass else {
            return
        }

        shadowLayer.shadowColor = Appearance.shadowColor.cgColor
        shadowLayer.shadowOpacity = Appearance.shadowOpacity
        shadowLayer.shadowRadius = Appearance.shadowRadius
        shadowLayer.shadowOffset = Appearance.shadowOffset
        layer.insertSublayer(shadowLayer, at: 0)

        shadowMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        shadowLayer.mask = shadowMaskLayer

        updateShadowPath()
    }

    private func updateShadowPath() {
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowLayer.shadowPath = shadowPath

        // Construct a mask path with the notice's roundrect cut out of a larger padding rect.
        // This, combined with the `kCAFillRuleEvenOdd` gives us an inverted mask, so
        // the shadow only appears _outside_ of the notice roundrect, and doesn't appear underneath
        // and obscure the blur visual effect view.
        let maskPath = CGMutablePath()
        let inset = Appearance.shadowRadius * 3
        maskPath.addRect(bounds.insetBy(dx: -inset, dy: -inset))
        maskPath.addPath(shadowPath)
        shadowMaskLayer.path = maskPath
    }

    /// Capsule-shaped while the notice is short, with continuous rounded corners once it grows taller.
    private var cornerRadius: CGFloat {
        min(bounds.height / 2, Metrics.maximumCornerRadius)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.layer.cornerRadius = cornerRadius
        updateShadowPath()
    }

    internal func configureContentStackView() {
        contentStackView.axis = .horizontal
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(contentStackView)
        backgroundView.contentView.pinSubviewToAllEdges(contentStackView)
    }

    private func configureHeader() {
        headerStackView.axis = .horizontal
        headerStackView.alignment = headerAlignment
        headerStackView.spacing = Metrics.iconSpacing
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.directionalLayoutMargins = notice.style.directionalLayoutMargins

        if let icon = Appearance.icon(for: notice) {
            iconView.image = icon.image
            iconView.tintColor = icon.color
            iconView.preferredSymbolConfiguration = iconSymbolConfiguration
            iconView.setContentHuggingPriority(.required, for: .horizontal)
            iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
            headerStackView.addArrangedSubview(iconView)
        }

        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Metrics.labelLineSpacing

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        headerStackView.addArrangedSubview(labelStackView)
        contentStackView.addArrangedSubview(headerStackView)

        titleLabel.font = notice.style.titleLabelFont
        messageLabel.font = notice.style.messageLabelFont
        titleLabel.adjustsFontForContentSizeCategory = true
        messageLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = notice.style.titleColor
        messageLabel.textColor = notice.style.messageColor

        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        if notice.cancelTitle != nil {
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Appearance.minMessageHeight).isActive =
                true
        }
    }

    private func configureActionButton() {
        guard let actionTitle = notice.actionTitle else {
            actionBackgroundView.isHidden = true
            return
        }

        actionButton.setTitle(actionTitle, for: .normal)

        contentStackView.addArrangedSubview(actionBackgroundView)
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        actionBackgroundView.directionalLayoutMargins = actionLayoutMargins

        actionBackgroundView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)

        actionButton.titleLabel?.font = notice.style.actionButtonFont
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setTitleColor(Appearance.actionColor, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    /// The labels already have a trailing margin, so the action button doesn't need a leading one.
    private var actionLayoutMargins: NSDirectionalEdgeInsets {
        var margins = notice.style.directionalLayoutMargins
        margins.leading = 0
        return margins
    }

    /// Below the labels, the action button lines up with them and doesn't need a top margin.
    private var stackedActionLayoutMargins: NSDirectionalEdgeInsets {
        var margins = notice.style.directionalLayoutMargins
        margins.top = 0
        return margins
    }

    private func configureDualButtons() {
        guard let actionTitle = notice.actionTitle,
            let cancelTitle = notice.cancelTitle
        else {
            actionBackgroundView.isHidden = true
            return
        }

        actionButton.setTitle(actionTitle, for: .normal)
        cancelButton.setTitle(cancelTitle, for: .normal)

        contentStackView.axis = .vertical

        let cancelBackgroundView = UIView()
        let buttonStackView = UIStackView(arrangedSubviews: [cancelBackgroundView, actionBackgroundView])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal

        buttonStackView.distribution = .fillEqually
        contentStackView.addArrangedSubview(buttonStackView)

        dualButtonsStackView = buttonStackView

        actionButton.titleLabel?.lineBreakMode = .byWordWrapping
        cancelButton.titleLabel?.lineBreakMode = .byWordWrapping
        actionButton.titleLabel?.numberOfLines = 0
        cancelButton.titleLabel?.numberOfLines = 0
        actionButton.titleLabel?.textAlignment = .center
        cancelButton.titleLabel?.textAlignment = .center
        if let label = actionButton.titleLabel {
            actionButton.pinSubviewToAllEdgeMargins(label)
        }
        if let label = cancelButton.titleLabel {
            cancelButton.pinSubviewToAllEdgeMargins(label)
        }

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        cancelBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        actionBackgroundView.addSubview(actionButton)
        actionBackgroundView.directionalLayoutMargins = Metrics.dualLayoutMargins
        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)
        actionBackgroundView.addTopBorder()

        cancelBackgroundView.addSubview(cancelButton)
        cancelBackgroundView.directionalLayoutMargins = Metrics.dualLayoutMargins
        cancelBackgroundView.pinSubviewToAllEdgeMargins(cancelButton)
        cancelBackgroundView.addTopBorder()
        cancelBackgroundView.addTrailingBorder()

        actionButton.titleLabel?.font = notice.style.actionButtonFont
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setTitleColor(Appearance.actionColor, for: .normal)
        actionButton.on(.touchUpInside) { [weak self] _ in
            self?.actionButtonTapped()
        }
        actionButton.setContentCompressionResistancePriority(.required, for: .vertical)

        cancelButton.titleLabel?.font = notice.style.cancelButtonFont
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.setTitleColor(notice.style.titleColor, for: .normal)
        cancelButton.on(.touchUpInside) { [weak self] _ in
            self?.cancelButtonTapped()
        }
        cancelButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func configureActionButtonWithArrow() {
        guard let actionTitle = notice.actionTitle,
            notice.style.showNextArrow
        else {
            actionBackgroundView.isHidden = true
            return
        }

        contentStackView.addArrangedSubview(actionBackgroundView)
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        actionBackgroundView.directionalLayoutMargins = actionLayoutMargins

        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.titleLabel?.font = notice.style.actionButtonFont
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setTitleColor(Appearance.actionColor, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        actionBackgroundView.addSubviews([actionButton, nextArrowImageView])

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        nextArrowImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionButton.centerYAnchor.constraint(equalTo: actionBackgroundView.centerYAnchor),
            actionButton.leadingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.leadingAnchor),
            actionButton.topAnchor.constraint(greaterThanOrEqualTo: actionBackgroundView.topAnchor),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: actionBackgroundView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            nextArrowImageView.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            nextArrowImageView.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 4),
            nextArrowImageView.trailingAnchor.constraint(
                equalTo: actionBackgroundView.layoutMarginsGuide.trailingAnchor
            )
        ])
    }

    private func configureNextArrow() -> UIImageView {
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        arrowImageView.tintColor = Appearance.actionColor
        arrowImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .footnote,
            scale: .medium
        )
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return arrowImageView
    }

    private var iconSymbolConfiguration: UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(font: notice.style.titleLabelFont, scale: .large)
    }

    /// SF Symbols carry a text baseline, so `.firstBaseline` lines the icon up with the title's first line.
    /// At accessibility sizes the text wraps over many lines, and the icon reads better centered on all of it.
    private var headerAlignment: UIStackView.Alignment {
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .center : .firstBaseline
    }

    private func preferredContentSizeDidChange() {
        iconView.preferredSymbolConfiguration = iconSymbolConfiguration
        headerStackView.alignment = headerAlignment

        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        dualButtonsStackView?.axis = isAccessibilityCategory ? .vertical : .horizontal

        // At accessibility sizes a single action moves below the labels, so they keep the full width.
        if dualButtonsStackView == nil && notice.actionTitle != nil {
            contentStackView.axis = isAccessibilityCategory ? .vertical : .horizontal
            actionBackgroundView.directionalLayoutMargins =
                isAccessibilityCategory ? stackedActionLayoutMargins : actionLayoutMargins
            if notice.style.showNextArrow {
                actionButton.contentHorizontalAlignment = isAccessibilityCategory ? .trailing : .center
            } else {
                actionButton.contentHorizontalAlignment = isAccessibilityCategory ? .leading : .center
            }
            // Beside the labels the button keeps to its title's width; below them it spans the notice.
            actionButton.setContentHuggingPriority(isAccessibilityCategory ? .defaultLow : .required, for: .horizontal)
        }
    }

    private func configureDismissRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapRecognizer)

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(viewTapped))
        swipeRecognizer.direction = .down
        addGestureRecognizer(swipeRecognizer)
    }

    private func configureForNotice() {
        titleLabel.text = notice.title

        if let attributedMessage = notice.style.attributedMessage {
            messageLabel.attributedText = attributedMessage
            titleLabel.isHidden = true
        } else if let message = notice.message {
            messageLabel.text = message
        } else {
            messageLabel.isHidden = true
        }
    }

    // MARK: - Action handlers

    @objc private func viewTapped() {
        dismissHandler?()
    }

    @objc private func actionButtonTapped() {
        notice.actionHandler?(true)
        dismissHandler?()
    }

    @objc private func cancelButtonTapped() {
        notice.actionHandler?(false)
        dismissHandler?()
    }

    private enum Metrics {
        static let maximumCornerRadius: CGFloat = 26.0
        static let dualLayoutMargins = NSDirectionalEdgeInsets(top: 6.0, leading: 6.0, bottom: 6.0, trailing: 6.0)
        static let labelLineSpacing: CGFloat = 2.0
        static let iconSpacing: CGFloat = 10.0
    }

    fileprivate enum Appearance {
        static var usesGlass: Bool {
            if #available(iOS 26, *) {
                return true
            }
            return false
        }

        static func makeBackgroundEffect() -> UIVisualEffect {
            if #available(iOS 26, *) {
                return UIGlassEffect()
            }
            return UIBlurEffect(style: .systemThickMaterial)
        }

        static func icon(for notice: Notice) -> (image: UIImage?, color: UIColor)? {
            if let icon = notice.style.icon {
                return (icon, actionColor)
            }
            switch notice.feedbackType {
            case .success:
                return (UIImage(systemName: "checkmark.circle.fill"), .systemGreen)
            case .error:
                return (UIImage(systemName: "exclamationmark.circle.fill"), .systemRed)
            case .warning, .none:
                return nil
            @unknown default:
                return nil
            }
        }

        static var actionColor: UIColor { UIAppColor.primary }

        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.12
        static let shadowRadius: CGFloat = 12.0
        static let shadowOffset = CGSize(width: 0.0, height: 4.0)
        static let minMessageHeight: CGFloat = 18.0
    }
}

fileprivate extension UIView {
    func addTopBorder() {
        let borderView = makeBorderView()

        NSLayoutConstraint.activate([
            makeHairlineConstraint(for: borderView.heightAnchor),
            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            borderView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    func addTrailingBorder() {
        let borderView = makeBorderView()

        NSLayoutConstraint.activate([
            borderView.heightAnchor.constraint(equalTo: heightAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.centerYAnchor.constraint(equalTo: centerYAnchor),
            makeHairlineConstraint(for: borderView.widthAnchor)
        ])
    }

    func makeBorderView() -> UIView {
        let borderView = UIView()
        borderView.backgroundColor = .separator
        borderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(borderView)

        return borderView
    }
}

// MARK: - VoiceOver

private extension NoticeView {
    func configureForAccessibility() {
        labelStackView.accessibilityLabel = [titleLabel, messageLabel]
            .filter { !$0.isHidden }
            .compactMap(\.text)
            .joined(separator: ". ")

        labelStackView.isAccessibilityElement = true
        labelStackView.accessibilityIdentifier = "notice_title_and_message"
    }
}
