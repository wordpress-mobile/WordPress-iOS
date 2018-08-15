class QuickStartNoticeView: UIView, DismissableNoticeView {
    private let contentStackView = UIStackView()
    private let backgroundContainerView = UIView()
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let yesButton = UIButton(type: .system)
    private let noButton = UIButton(type: .system)
    private let formattedMessage: NSAttributedString?
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    private let notice: Notice

    required init(notice: Notice, message formattedMessage: NSAttributedString?) {
        self.notice = notice
        self.formattedMessage = formattedMessage

        super.init(frame: .zero)

        configureBackgroundViews()
        configureShadow()
        configureContentStackView()
        configureLabels()
        configureForNotice()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var dismissHandler: (() -> Void)?

    override var bounds: CGRect {
        didSet {
            updateShadowPath()
        }
    }
}
private extension QuickStartNoticeView {

    private func configureContentStackView() {
        contentStackView.axis = .horizontal
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(contentStackView)
        backgroundView.pinSubviewToAllEdges(contentStackView)
    }

    func configureBackgroundViews() {
        backgroundView.backgroundColor = Colors.backgroundColor

        addSubview(backgroundContainerView)
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundContainerView)

        backgroundContainerView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)

        backgroundContainerView.layer.cornerRadius = Metrics.cornerRadius
        backgroundContainerView.layer.masksToBounds = true
    }

    private func configureShadow() {
        shadowLayer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: Metrics.cornerRadius).cgPath
        shadowLayer.shadowColor = ShadowAppearance.shadowColor.cgColor
        shadowLayer.shadowOpacity = ShadowAppearance.shadowOpacity
        shadowLayer.shadowRadius = ShadowAppearance.shadowRadius
        shadowLayer.shadowOffset = ShadowAppearance.shadowOffset
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

    func configureLabels() {
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
            labelStackView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
            ])

        titleLabel.font = Fonts.titleLabelFont
        messageLabel.font = Fonts.messageLabelFont

        titleLabel.textColor = Colors.titleColor
        messageLabel.textColor = Colors.messageColor
    }


    private func configureForNotice() {
        titleLabel.text = notice.title

        if let message = formattedMessage {
            messageLabel.attributedText = message
            titleLabel.isHidden = true
        } else if let message = notice.message {
            messageLabel.text = message
        } else {
            titleLabel.numberOfLines = 2
        }
    }

    enum Fonts {
        static let actionButtonFont = UIFont.systemFont(ofSize: 14.0)
        static let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
    }

    enum Colors {
        static let backgroundColor = WPStyleGuide.darkGrey().withAlphaComponent(0.88)
        static let titleColor = UIColor.white
        static let messageColor = WPStyleGuide.greyLighten20()
    }

    enum Metrics {
        static let cornerRadius: CGFloat = 14.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let labelLineSpacing: CGFloat = 18.0
    }

    enum ShadowAppearance {
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.25
        static let shadowRadius: CGFloat = 8.0
        static let shadowOffset = CGSize(width: 0.0, height: 2.0)
    }
}
