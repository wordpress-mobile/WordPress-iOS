class LoginSocialErrorCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let labelStack = UIStackView()

    private struct Constants {
        static let labelSpacing: CGFloat = 15.0
        static let labelVerticalMargin: CGFloat = 20.0
        static let descriptionMinHeight: CGFloat = 14.0
    }

    @objc init(title: String, description: String) {
        super.init(style: .default, reuseIdentifier: "LoginSocialErrorCell")
        titleLabel.text = title
        descriptionLabel.text = description
        layoutLabels()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutLabels()
    }

    required init?(coder aDecoder: NSCoder) {
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

        titleLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        titleLabel.textColor = WPStyleGuide.greyDarken30()
        descriptionLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        descriptionLabel.textColor = WPStyleGuide.darkGrey()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.descriptionMinHeight).isActive = true

        contentView.addConstraints([
            contentView.topAnchor.constraint(equalTo: labelStack.topAnchor, constant: Constants.labelVerticalMargin * -1.0),
            contentView.bottomAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: Constants.labelVerticalMargin),
            contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor)
            ])

        backgroundColor = WPStyleGuide.greyLighten30()
    }

    func configureCell(_ errorTitle: String, errorDescription: String) {
        titleLabel.text = errorTitle.localizedUppercase
        descriptionLabel.text = errorDescription
    }
}
