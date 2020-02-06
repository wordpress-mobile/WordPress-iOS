class NewBlogDetailHeaderView: UIView {

    @objc var delegate: BlogDetailHeaderViewDelegate?

    //TODO: Add drop target

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
        label.textColor = UIColor.textSubtle
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let siteIconView: SiteIconView = {
        let view = SiteIconView(frame: .zero)
        return view
    }()

    @objc var updatingIcon: Bool = false {
        didSet {
            if updatingIcon {
                siteIconView.activityIndicator.startAnimating()
            } else {
                siteIconView.activityIndicator.stopAnimating()
            }
        }
    }

    @objc var blavatarImageView: UIImageView {
        return siteIconView.imageView
    }

    @objc var blog: Blog? {
        didSet {
            refreshIconImage()

            let blogName = blog?.settings?.name
            let title = blogName != nil && blogName?.isEmpty == false ? blogName : blog?.displayURL as String?
            titleLabel.text = title
            subtitleLabel.text = blog?.displayURL as String?
        }
    }

    func refreshIconImage() {
        if let blog = blog,
            blog.hasIcon == true {
            siteIconView.imageView.downloadSiteIcon(for: blog)
        } else {
            siteIconView.imageView.image = UIImage.siteIconPlaceholder
        }

        //TODO: Refresh spotlight view
    }

    private enum Constants {
        static let spacingBelowIcon: CGFloat = 16
        static let spacingBelowTitle: CGFloat = 8
        static let interSectionSpacing: CGFloat = 32
        static let buttonsBottomPadding: CGFloat = 40
        static let buttonsSidePadding: CGFloat = 40
        static let buttonsMinSidePadding: CGFloat = 0
    }

    convenience init(items: [ActionRow.Item]) {

        self.init(frame: .zero)

        siteIconView.callback = { [weak self] in
            self?.delegate?.siteIconTapped()
        }

        let buttonsStackView = ActionRow(items: items)

        let stackView = UIStackView(arrangedSubviews: [
            siteIconView,
            titleLabel,
            subtitleLabel,
        ])

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        addSubview(buttonsStackView)


        // Set up constraints for spacing

        stackView.setCustomSpacing(Constants.spacingBelowIcon, after: siteIconView)
        stackView.setCustomSpacing(Constants.spacingBelowTitle, after: titleLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.interSectionSpacing)
        ])

        let normalSideConstraints = [
            buttonsStackView.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: -Constants.buttonsSidePadding),
            buttonsStackView.leadingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor, constant: Constants.buttonsSidePadding)
        ]

        NSLayoutConstraint.activate(normalSideConstraints)

        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.interSectionSpacing),
            buttonsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: stackView.leadingAnchor, constant: Constants.buttonsMinSidePadding),
            buttonsStackView.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: -Constants.buttonsMinSidePadding),
            buttonsStackView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.buttonsBottomPadding),
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
