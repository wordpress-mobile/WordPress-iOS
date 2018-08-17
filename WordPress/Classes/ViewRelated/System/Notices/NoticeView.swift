import UIKit

class NoticeView: UIView {
    internal let contentStackView = UIStackView()
    internal let backgroundContainerView = UIView()
    internal let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    internal let actionBackgroundView = UIView()
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    internal let titleLabel = UILabel()
    internal let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    internal let notice: Notice

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
        configureActionButton()
        configureDismissRecognizer()
        configureForNotice()
    }

    private func configureBackgroundViews() {
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

        shadowMaskLayer.fillRule = kCAFillRuleEvenOdd
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
        let leftInset = Metrics.layoutMargins.left * 2
        let topInset = Metrics.layoutMargins.top * 2
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

    private func configureLabels() { //**
        let labelStackView = UIStackView()
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Metrics.labelLineSpacing
        labelStackView.isBaselineRelativeArrangement = true
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = Metrics.layoutMargins

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        contentStackView.addArrangedSubview(labelStackView)

        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor)
            ])

        titleLabel.font = Fonts.titleLabelFont
        messageLabel.font = Fonts.messageLabelFont

        titleLabel.textColor = WPStyleGuide.darkGrey()
        messageLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func configureActionButton() {
        contentStackView.addArrangedSubview(actionBackgroundView)
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        actionBackgroundView.layoutMargins = Metrics.layoutMargins
        actionBackgroundView.backgroundColor = Appearance.actionBackgroundColor

        actionBackgroundView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionBackgroundView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            actionBackgroundView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),
            ])

        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)

        actionButton.titleLabel?.font = Fonts.actionButtonFont
        actionButton.setTitleColor(WPStyleGuide.mediumBlue(), for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)
    }

    private func configureForNotice() {
        titleLabel.text = notice.title

        if let message = notice.message {
            messageLabel.text = message
        } else {
            titleLabel.numberOfLines = 2
        }

        if let actionTitle = notice.actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
        } else {
            actionBackgroundView.isHidden = true
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
        notice.actionHandler?()
        dismissHandler?()
    }

    private enum Metrics {
        static let cornerRadius: CGFloat = 13.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let labelLineSpacing: CGFloat = 18.0
    }

    private enum Fonts {
        static let actionButtonFont = UIFont.systemFont(ofSize: 14.0)
        static let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
    }

    private enum Appearance {
        static let actionBackgroundColor = UIColor.white.withAlphaComponent(0.5)
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.25
        static let shadowRadius: CGFloat = 8.0
        static let shadowOffset = CGSize(width: 0.0, height: 2.0)
    }
}
