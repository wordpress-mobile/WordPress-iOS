class QuickStartNoticeView: NoticeView {
    private let yesButton = UIButton(type: .system)
    private let noButton = UIButton(type: .system)

    override func configure() {
        configureBackgroundViews()
        configureShadow()
        configureContentStackView()
        configureLabels()
        configureForNotice()
    }

    static func makeHighlightMessage(base normalString: String, highlight: String, icon: UIImage) -> NSAttributedString {
        let normalParts = normalString.components(separatedBy: "%@")
        guard normalParts.count > 0 else {
            // if the provided base doesn't contain %@ then we don't know where to place the highlight
            return NSAttributedString(string: normalString)
        }
        let resultString = NSMutableAttributedString(string: normalParts[0])

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = icon.imageWithTintColor(HighlightConstants.highlightColor)
        iconAttachment.bounds = CGRect(x: 0.0, y: font.descender + HighlightConstants.iconOffset, width: HighlightConstants.iconSize, height: HighlightConstants.iconSize)
        let iconStr = NSAttributedString(attachment: iconAttachment)

        let highlightStr = NSAttributedString(string: highlight, attributes: [.foregroundColor: HighlightConstants.highlightColor, .font: HighlightConstants.highlightFont])

        switch UIView.userInterfaceLayoutDirection(for: .unspecified) {
        case .rightToLeft:
            resultString.append(highlightStr)
            resultString.append(NSAttributedString(string: " "))
            resultString.append(iconStr)
        default:
            resultString.append(iconStr)
            resultString.append(NSAttributedString(string: " "))
            resultString.append(highlightStr)
        }

        if normalParts.count > 1 {
            resultString.append(NSAttributedString(string: normalParts[1]))
        }

        return resultString
    }

    private enum HighlightConstants {
        static let iconOffset: CGFloat = 1.0
        static let iconSize: CGFloat = 16.0
        static let highlightColor = WPStyleGuide.lightBlue()
        static var highlightFont: UIFont {
            get {
                return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            }
        }
    }
}

private extension QuickStartNoticeView {

    func configureBackgroundViews() {
        // dark background view
        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = Colors.backgroundColor
        backgroundView.contentView.addSubview(backgroundColorView)
        backgroundColorView.layer.cornerRadius = Metrics.cornerRadius
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.pinSubviewToAllEdges(backgroundColorView)

        addSubview(backgroundContainerView)
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundContainerView)

        backgroundContainerView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)

        backgroundContainerView.layer.cornerRadius = Metrics.cornerRadius //**
        backgroundContainerView.layer.masksToBounds = true
    }

    func configureLabels() { // **
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


    func configureForNotice() {
        titleLabel.text = notice.title

        if case .quickStart(let message) = notice.style {
            messageLabel.attributedText = message
            titleLabel.isHidden = true
        } else if let message = notice.message {
            messageLabel.text = message
        } else {
            titleLabel.numberOfLines = 2
        }
        titleLabel.font = Fonts.titleLabelFont
        messageLabel.font = Fonts.messageLabelFont
        messageLabel.textColor = Colors.messageColor
    }

    enum Fonts {
        static let titleLabelFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        static var messageLabelFont: UIFont {
            get {
                return WPStyleGuide.fontForTextStyle(.subheadline)
            }
        }
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
}
