import UIKit

class NoticeView: UIView {
    internal let contentStackView = UIStackView()

    internal let backgroundContainerView = UIView()
    internal let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    internal let actionBackgroundView = UIView()
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    /// Container for the title and content labels
    private let labelStackView = UIStackView()
    internal let titleLabel = UILabel()
    internal let messageLabel = UILabel()

    private let actionButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    internal let notice: Notice
    internal var dualButtonsStackView: UIStackView?

    var dismissHandler: (() -> Void)?

    required init(notice: Notice) {
        self.notice = notice

        super.init(frame: .zero)

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// configure the NoticeView for display
    internal func configure() {
        configureBackgroundViews()
        configureShadow()
        configureContentStackView()
        configureLabels()
        configureForNotice()

        if notice.actionTitle != nil && notice.cancelTitle != nil {
            configureDualButtons()
        } else if notice.actionTitle != nil {
            configureActionButton()
        }

        if notice.style.isDismissable {
            configureDismissRecognizer()
        }

        configureForAccessibility()
    }

    private func configureBackgroundViews() {
        if notice.style.backgroundColor != .clear {
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = notice.style.backgroundColor
            backgroundView.contentView.addSubview(backgroundColorView)
            backgroundColorView.layer.cornerRadius = Metrics.cornerRadius
            backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.contentView.pinSubviewToAllEdges(backgroundColorView)
        }

        addSubview(backgroundContainerView)
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundContainerView)

        backgroundContainerView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)

        backgroundContainerView.layer.cornerRadius = Metrics.cornerRadius
        backgroundContainerView.layer.masksToBounds = true
    }

    internal func configureShadow() {
        shadowLayer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: Metrics.cornerRadius).cgPath
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
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Metrics.cornerRadius).cgPath
        shadowLayer.shadowPath = shadowPath

        // Construct a mask path with the notice's roundrect cut out of a larger padding rect.
        // This, combined with the `kCAFillRuleEvenOdd` gives us an inverted mask, so
        // the shadow only appears _outside_ of the notice roundrect, and doesn't appear underneath
        // and obscure the blur visual effect view. 
        let maskPath = CGMutablePath()
        let leftInset = notice.style.layoutMargins.left * 2
        let topInset = notice.style.layoutMargins.top * 2
        maskPath.addRect(bounds.insetBy(dx: -leftInset, dy: -topInset))
        maskPath.addPath(shadowPath)
        shadowMaskLayer.path = maskPath
    }

    internal func configureContentStackView() {
        contentStackView.axis = .horizontal
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(contentStackView)
        backgroundView.contentView.pinSubviewToAllEdges(contentStackView)
    }

    private func configureLabels() {
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Metrics.labelLineSpacing
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = notice.style.layoutMargins

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        contentStackView.addArrangedSubview(labelStackView)

        labelStackView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor).isActive = true
        titleLabel.adjustsFontForContentSizeCategory = true
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        titleLabel.textColor = notice.style.titleColor
        messageLabel.textColor = notice.style.messageColor

        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        if notice.cancelTitle != nil {
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Appearance.minMessageHeight).isActive = true
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

        actionBackgroundView.layoutMargins = notice.style.layoutMargins
        actionBackgroundView.backgroundColor = notice.style.backgroundColor

        actionBackgroundView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionBackgroundView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            actionBackgroundView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),
            ])

        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)

        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setTitleColor(.primary(.shade40), for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureDualButtons() {
        guard let actionTitle = notice.actionTitle,
            let cancelTitle = notice.cancelTitle else {
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
        actionBackgroundView.layoutMargins = Metrics.dualLayoutMargins
        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)
        actionBackgroundView.addTopBorder()

        cancelBackgroundView.addSubview(cancelButton)
        cancelBackgroundView.layoutMargins = Metrics.dualLayoutMargins
        cancelBackgroundView.pinSubviewToAllEdgeMargins(cancelButton)
        cancelBackgroundView.addTopBorder()
        cancelBackgroundView.addTrailingBorder()

        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.on(.touchUpInside) { [weak self] _ in
            self?.actionButtonTapped()
        }
        actionButton.setContentCompressionResistancePriority(.required, for: .vertical)

        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.setTitleColor(notice.style.messageColor, for: .normal)
        cancelButton.on(.touchUpInside) { [weak self] _ in
            self?.cancelButtonTapped()
        }
        cancelButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    private func preferredContentSizeDidChange() {
        cancelButton.titleLabel?.font = notice.style.cancelButtonFont
        actionButton.titleLabel?.font = notice.style.actionButtonFont
        titleLabel.font = notice.style.titleLabelFont

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            dualButtonsStackView?.axis = .vertical
            actionButton.titleLabel?.textAlignment = .center
            cancelButton.titleLabel?.textAlignment = .center
        } else {
            dualButtonsStackView?.axis = .horizontal
            actionButton.titleLabel?.textAlignment = .natural
            cancelButton.titleLabel?.textAlignment = .natural
        }
    }

    private func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)
    }

    private func configureForNotice() {
        titleLabel.text = notice.title

        if let attributedMessage = notice.style.attributedMessage {
            messageLabel.attributedText = attributedMessage
            titleLabel.isHidden = true
        } else if let message = notice.message {
            messageLabel.text = message
        }
    }

    override var bounds: CGRect {
        didSet {
            updateShadowPath()
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

    private func cancelButtonTapped() {
        notice.actionHandler?(false)
        dismissHandler?()
    }

    private enum Metrics {
        static let cornerRadius: CGFloat = 4.0
        static let dualLayoutMargins = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)
        static let labelLineSpacing: CGFloat = 3.0
    }

    private enum Appearance {
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.25
        static let shadowRadius: CGFloat = 2.0
        static let shadowOffset = CGSize(width: 0.0, height: 2.0)
        static let minMessageHeight: CGFloat = 18.0
    }
}

fileprivate extension UIView {
    func addTopBorder() {
        let borderView = makeBorderView()

        NSLayoutConstraint.activate([
            borderView.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
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
            borderView.widthAnchor.constraint(equalToConstant: .hairlineBorderWidth)
            ])
    }

    func makeBorderView() -> UIView {
        let borderView = UIView()
        borderView.backgroundColor = Constants.borderColor
        borderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(borderView)

        return borderView
    }

    struct Constants {
        static let borderColor = UIColor.white.withAlphaComponent(0.25)
    }
}

// MARK: - VoiceOver

private extension NoticeView {
    func configureForAccessibility() {
        labelStackView.accessibilityLabel = [titleLabel, messageLabel].compactMap {
            return $0.isHidden ? "" : $0.text
        }.joined(separator: ". ")

        labelStackView.isAccessibilityElement = true
        labelStackView.accessibilityIdentifier = "notice_title_and_message"
    }
}
