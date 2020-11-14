class NewBlogDetailHeaderView: UIView, BlogDetailHeader {

    @objc weak var delegate: BlogDetailHeaderViewDelegate?

    // Temporary method for migrating to NewBlogDetailHeaderView
    @objc
    var asView: UIView {
        return self
    }

    private let titleButton: SpotlightableButton = {
        let button = SpotlightableButton(type: .custom)
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setTitleColor(.text, for: .normal)
        button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return button
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
            toggleSpotlightOnSiteTitle()
            refreshSiteTitle()
            subtitleLabel.text = blog?.displayURL as String?

            siteIconView.allowsDropInteraction = delegate?.siteIconShouldAllowDroppedImages() == true
        }
    }

    @objc func refreshIconImage() {
        if let blog = blog,
            blog.hasIcon == true {
            siteIconView.imageView.downloadSiteIcon(for: blog)
        } else {
            siteIconView.imageView.image = UIImage.siteIconPlaceholder
        }

        toggleSpotlightOnSiteIcon()
    }

    func refreshSiteTitle() {
        let blogName = blog?.settings?.name
        let title = blogName != nil && blogName?.isEmpty == false ? blogName : blog?.displayURL as String?
        titleButton.setTitle(title, for: .normal)
    }

    @objc func toggleSpotlightOnSiteTitle() {
        titleButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.siteTitle)
    }

    @objc func toggleSpotlightOnSiteIcon() {
        siteIconView.spotlightIsShown = QuickStartTourGuide.shared.isCurrentElement(.siteIcon)
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
            QuickStartTourGuide.shared.visited(.siteIcon)
            self?.siteIconView.spotlightIsShown = false

            self?.delegate?.siteIconTapped()
        }

        siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
        }

        let buttonsStackView = ActionRow(items: items)

        let stackView = UIStackView(arrangedSubviews: [
            siteIconView,
            titleButton,
            subtitleLabel,
        ])

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        addSubview(buttonsStackView)

        stackView.setCustomSpacing(Constants.spacingBelowIcon, after: siteIconView)
        stackView.setCustomSpacing(Constants.spacingBelowTitle, after: titleButton)

        /// Constraints for constrained widths (iPad portrait)
        let minimumPaddingSideConstraints: [NSLayoutConstraint] = [
            buttonsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: stackView.leadingAnchor, constant: 0),
            buttonsStackView.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: 0),
        ]

        let bottomConstraint = buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.buttonsBottomPadding)
        bottomConstraint.priority = UILayoutPriority(999) // Allow to break so encapsulated height (on initial table view load) doesn't spew warnings

        let widthConstraint = buttonsStackView.widthAnchor.constraint(equalToConstant: 320)
        widthConstraint.priority = .defaultHigh

        let stackViewConstraints = [
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Constants.minimumSideSpacing),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.interSectionSpacing),
            stackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
        ]
        stackViewConstraints.forEach { $0.priority = UILayoutPriority(999) }

        let edgeConstraints = [
            buttonsStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.interSectionSpacing),
            buttonsStackView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            bottomConstraint,
            widthConstraint
        ]

        NSLayoutConstraint.activate(minimumPaddingSideConstraints + edgeConstraints + stackViewConstraints)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func titleButtonTapped() {
        QuickStartTourGuide.shared.visited(.siteTitle)
        titleButton.shouldShowSpotlight = false

        delegate?.siteTitleTapped()
    }
}
