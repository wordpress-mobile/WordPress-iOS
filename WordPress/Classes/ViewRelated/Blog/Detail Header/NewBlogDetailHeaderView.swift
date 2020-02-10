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

            siteIconView.allowsDropInteraction = delegate?.siteIconShouldAllowDroppedImages() == true
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
        static let minimumSideSpacing: CGFloat = 8
        static let interSectionSpacing: CGFloat = 32
        static let buttonsBottomPadding: CGFloat = 40
        static let buttonsSidePadding: CGFloat = 40
    }

    convenience init(items: [ActionRow.Item]) {

        self.init(frame: .zero)

        siteIconView.tapped = { [weak self] in
            self?.delegate?.siteIconTapped()
        }

        siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
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

        stackView.setCustomSpacing(Constants.spacingBelowIcon, after: siteIconView)
        stackView.setCustomSpacing(Constants.spacingBelowTitle, after: titleLabel)

        /// Constraints for larger widths with extra padding (iPhone portrait)
        let extraPaddingSideConstraints = [
            buttonsStackView.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: -Constants.buttonsSidePadding),
            buttonsStackView.leadingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor, constant: Constants.buttonsSidePadding)
        ]

        /// Constraints for constrained widths (iPad portrait)
        let minimumPaddingSideConstraints = [
            buttonsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: stackView.leadingAnchor, constant: 0),
            buttonsStackView.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: 0),
        ]

        let bottomConstraint = buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.buttonsBottomPadding)
        bottomConstraint.priority = UILayoutPriority(999) // Allow to break so encapsulated height (on initial table view load) doesn't spew warnings

        /// If we are able to attach to the safe area's leading edge, we should, otherwise it can break
        let leadingSafeAreaConstraint = stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor)
        leadingSafeAreaConstraint.priority = .defaultHigh

        let edgeConstraints = [
            leadingSafeAreaConstraint,
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Constants.minimumSideSpacing),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.interSectionSpacing),
            buttonsStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.interSectionSpacing),
            buttonsStackView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            bottomConstraint
        ]

        NSLayoutConstraint.activate(extraPaddingSideConstraints + minimumPaddingSideConstraints + edgeConstraints)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
