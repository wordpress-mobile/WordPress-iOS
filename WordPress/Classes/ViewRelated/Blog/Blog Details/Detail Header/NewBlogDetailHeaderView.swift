class NewBlogDetailHeaderView: UIView, BlogDetailHeader {
    
    // MARK: - Child Views
    
    private let actionRow: ActionRow
    private let titleView: TitleView
    
    // MARK: - Delegate
    
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

    @objc var updatingIcon: Bool = false {
        didSet {
            if updatingIcon {
                titleView.siteIconView.activityIndicator.startAnimating()
            } else {
                titleView.siteIconView.activityIndicator.stopAnimating()
            }
        }
    }

    @objc var blavatarImageView: UIImageView {
        return titleView.siteIconView.imageView
    }

    @objc var blog: Blog? {
        didSet {
            refreshIconImage()
            toggleSpotlightOnSiteTitle()
            refreshSiteTitle()
            subtitleLabel.text = blog?.displayURL as String?

            titleView.siteIconView.allowsDropInteraction = delegate?.siteIconShouldAllowDroppedImages() == true
        }
    }

    @objc func refreshIconImage() {
        if let blog = blog,
            blog.hasIcon == true {
            titleView.siteIconView.imageView.downloadSiteIcon(for: blog)
        } else {
            titleView.siteIconView.imageView.image = UIImage.siteIconPlaceholder
        }

        toggleSpotlightOnSiteIcon()
    }

    func refreshSiteTitle() {
        let blogName = blog?.settings?.name
        let title = blogName != nil && blogName?.isEmpty == false ? blogName : blog?.displayURL as String?
        //titleButton.setTitle(title, for: .normal)
        titleView.titleButton.setTitle(title, for: .normal)
    }

    @objc func toggleSpotlightOnSiteTitle() {
        titleButton.shouldShowSpotlight = QuickStartTourGuide.find()?.isCurrentElement(.siteTitle) == true
    }

    @objc func toggleSpotlightOnSiteIcon() {
        titleView.siteIconView.spotlightIsShown = QuickStartTourGuide.find()?.isCurrentElement(.siteIcon) == true
    }

    private enum LayoutSpacing {
        static let atSides: CGFloat = 16
        static let top: CGFloat = 24
        static let belowActionRow: CGFloat = 16
        static let betweenTitleViewAndActionRow: CGFloat = 32
        
        static let spacingBelowIcon: CGFloat = 16
        static let spacingBelowTitle: CGFloat = 8
        static let minimumSideSpacing: CGFloat = 8
        static let interSectionSpacing: CGFloat = 32
        static let buttonsBottomPadding: CGFloat = 40
        static let buttonsSidePadding: CGFloat = 40
    }
    
    // MARK: - Initializers

    required init(items: [ActionRow.Item]) {
        actionRow = ActionRow(items: items)
        /*titleView = UIStackView(arrangedSubviews: [
            siteIconView,
            titleButton,
            subtitleLabel,
        ])*/
        titleView = TitleView(frame: .zero)
        
        super.init(frame: .zero)

        // Temporary so we can differentiate between this and the old blog details in the PR review.
        backgroundColor = .white
        
        setupChildViews(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Child View Initialization
    
    private func setupChildViews(items: [ActionRow.Item]) {
        titleView.siteIconView.tapped = { [weak self] in
            QuickStartTourGuide.find()?.visited(.siteIcon)
            self?.titleView.siteIconView.spotlightIsShown = false

            self?.delegate?.siteIconTapped()
        }

        titleView.siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
        }

        //titleView.axis = .vertical
        //titleView.alignment = .center
        //titleView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleView)
        addSubview(actionRow)
        
        setupConstraintsForChildViews()
    }
    
    // MARK: - Constraints
    
    private func setupConstraintsForChildViews() {
        let actionRowConstraints = constraintsForActionRow()
        let titleViewContraints = constraintsForTitleView()
            
        NSLayoutConstraint.activate(actionRowConstraints + titleViewContraints)
    }
    
    private func constraintsForActionRow() -> [NSLayoutConstraint] {
        [
            actionRow.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: LayoutSpacing.betweenTitleViewAndActionRow),
            actionRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -LayoutSpacing.belowActionRow),
            actionRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: LayoutSpacing.atSides),
            actionRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -LayoutSpacing.atSides)
        ]
    }
    
    private func constraintsForTitleView() -> [NSLayoutConstraint] {
        [
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutSpacing.top),
            titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: LayoutSpacing.atSides),
            titleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -LayoutSpacing.atSides)
        ]
        
        /*
        titleView.setCustomSpacing(LayoutSpacing.spacingBelowIcon, after: siteIconView)
        titleView.setCustomSpacing(LayoutSpacing.spacingBelowTitle, after: titleButton)

        let stackViewConstraints = [
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            titleView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: LayoutSpacing.minimumSideSpacing),
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutSpacing.interSectionSpacing),
            titleView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
        ]
        stackViewConstraints.forEach { $0.priority = UILayoutPriority(999) }
        
        NSLayoutConstraint.activate(stackViewConstraints)*/
    }
    
    // MARK: - User Action Handlers

    @objc private func titleButtonTapped() {
        QuickStartTourGuide.find()?.visited(.siteTitle)
        titleButton.shouldShowSpotlight = false

        delegate?.siteTitleTapped()
    }
}

fileprivate extension NewBlogDetailHeaderView {
    class TitleView: UIView {
        
        private enum Dimensions {
            static let siteIconHeight: CGFloat = 48
            static let siteIconWidth: CGFloat = 48
        }
        
        private enum LayoutSpacing {
            static let betweenSiteIconAndTitle: CGFloat = 16
            static let betweenTitleAndSiteSwitcher: CGFloat = 16
        }
        
        // MARK: - Child Views
        
        let siteIconView: SiteIconView = {
            let siteIconView = SiteIconView(frame: .zero)
            siteIconView.translatesAutoresizingMaskIntoConstraints = false
            return siteIconView
        }()
        
        let subtitleLabel: UILabel = {
            let label = UILabel()
            label.font = WPStyleGuide.fontForTextStyle(.footnote)
            label.textColor = UIColor.textSubtle
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        let titleButton: SpotlightableButton = {
            let button = SpotlightableButton(type: .custom)
            button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.setTitleColor(.text, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            //button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
            return button
        }()
        
        private(set) lazy var titleStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                titleButton,
                subtitleLabel
            ])
            
            stackView.alignment = .leading
            stackView.axis = .vertical
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            return stackView
        }()
        
        // MARK: - Initializers
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .systemPink
            
            setupChildViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Child View Setup
        
        private func setupChildViews() {
            addSubview(siteIconView)
            addSubview(titleStackView)
            
            titleStackView.backgroundColor = .green
            
            setupConstraintsForChildViews()
        }
        
        // MARK: - Constraints
        
        private func setupConstraintsForChildViews() {
            let siteIconConstraints = constraintsForSiteIcon()
            let titleStackViewConstraints = constraintsForTitleStackView()
            
            NSLayoutConstraint.activate(siteIconConstraints + titleStackViewConstraints)
        }
        
        private func constraintsForSiteIcon() -> [NSLayoutConstraint] {
            [
                siteIconView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                siteIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
                siteIconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
                siteIconView.widthAnchor.constraint(equalToConstant: Dimensions.siteIconWidth),
                siteIconView.heightAnchor.constraint(equalToConstant: Dimensions.siteIconHeight)
            ]
        }
        
        private func constraintsForTitleStackView() -> [NSLayoutConstraint] {
            [
                titleStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
                titleStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
                titleStackView.leadingAnchor.constraint(equalTo: siteIconView.trailingAnchor, constant: LayoutSpacing.betweenSiteIconAndTitle),
                titleStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -LayoutSpacing.betweenTitleAndSiteSwitcher),
                titleStackView.centerYAnchor.constraint(equalTo: siteIconView.centerYAnchor, constant: 0),
            ]
        }
    }
}
