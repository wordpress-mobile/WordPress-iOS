import WordPressShared

open class LoginSocialErrorCell: UITableViewCell {
    private let errorTitle: String
    private let errorDescription: String
    private var errorDescriptionStyled: NSAttributedString?
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel
    private let labelStack: UIStackView

    private var forUnified: Bool = false

    private struct Constants {
        static let labelSpacing: CGFloat = 15.0
        static let labelVerticalMargin: CGFloat = 20.0
        static let descriptionMinHeight: CGFloat = 14.0
    }

    @objc public init(title: String, description: String, forUnified: Bool = false) {
        errorTitle = title
        errorDescription = description
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        labelStack = UIStackView()
        self.forUnified = forUnified

        super.init(style: .default, reuseIdentifier: "LoginSocialErrorCell")

        layoutLabels()
    }

    public init(title: String, description styledDescription: NSAttributedString) {
        errorDescriptionStyled = styledDescription
        errorDescription = ""
        errorTitle = title
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        labelStack = UIStackView()

        super.init(style: .default, reuseIdentifier: "LoginSocialErrorCell")

        layoutLabels()
    }

    required public init?(coder aDecoder: NSCoder) {
        errorTitle = aDecoder.value(forKey: "errorTitle") as? String ?? ""
        errorDescription = aDecoder.value(forKey: "errorDescription") as? String ?? ""
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        labelStack = UIStackView()

        super.init(coder: aDecoder)

        layoutLabels()
    }

    private func layoutLabels() {
        contentView.addSubview(labelStack)
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.addArrangedSubview(titleLabel)
        labelStack.addArrangedSubview(descriptionLabel)
        labelStack.axis = .vertical
        labelStack.spacing = Constants.labelSpacing

        let style = WordPressAuthenticator.shared.style
        titleLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        titleLabel.textColor = style.instructionColor
        descriptionLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        descriptionLabel.textColor = style.subheadlineColor
        descriptionLabel.numberOfLines = 0
        descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.descriptionMinHeight).isActive = true

        contentView.addConstraints([
            contentView.topAnchor.constraint(equalTo: labelStack.topAnchor, constant: Constants.labelVerticalMargin * -1.0),
            contentView.bottomAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: Constants.labelVerticalMargin),
            contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor)
            ])

        titleLabel.text = errorTitle.localizedUppercase
        if let styledDescription = errorDescriptionStyled {
            descriptionLabel.attributedText = styledDescription
        } else {
            descriptionLabel.text = errorDescription
        }

        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
            return
        }

        backgroundColor = forUnified ? unifiedBackgroundColor : WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }
}
