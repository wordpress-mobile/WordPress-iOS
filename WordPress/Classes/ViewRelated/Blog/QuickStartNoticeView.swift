class QuickStartNoticeView: UIView, DismissableNoticeView {
    private let contentStackView = UIStackView()
    private let backgroundContainerView = UIView()
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let yesButton = UIButton(type: .system)
    private let noButton = UIButton(type: .system)
    private let formattedMessage: NSAttributedString?

    private let notice: Notice

    required init(notice: Notice, message formattedMessage: NSAttributedString?) {
        self.notice = notice
        self.formattedMessage = formattedMessage

        super.init(frame: .zero)

        configureBackgroundViews()
//        configureShadow()
        configureContentStackView()
        configureLabels()
//        configureActionButton()
//        configureDismissRecognizer()

        configureForNotice()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var dismissHandler: (() -> Void)?
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

//    enum colors
    enum Colors {
        static let backgroundColor = WPStyleGuide.darkGrey()
        static let titleColor = UIColor.white
        static let messageColor = WPStyleGuide.greyLighten20()
    }

    enum Metrics {
        static let cornerRadius: CGFloat = 14.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let labelLineSpacing: CGFloat = 18.0
    }
}
