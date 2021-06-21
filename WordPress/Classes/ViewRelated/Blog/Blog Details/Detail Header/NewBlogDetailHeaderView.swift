import Gridicons

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

            if let displayURL = blog?.displayURL as String? {
                titleView.set(url: displayURL)
            }

            titleView.siteIconView.allowsDropInteraction = delegate?.siteIconShouldAllowDroppedImages() == true
        }
    }

    @objc func refreshIconImage() {
        if let blog = blog,
            blog.hasIcon == true {
            titleView.siteIconView.imageView.downloadSiteIcon(for: blog)
        } else if let blog = blog,
            blog.isWPForTeams() {
            titleView.siteIconView.imageView.tintColor = UIColor.listIcon
            titleView.siteIconView.imageView.image = UIImage.gridicon(.p2)
        } else {
            titleView.siteIconView.imageView.image = UIImage.siteIconPlaceholder
        }

        toggleSpotlightOnSiteIcon()
    }

    func setTitleLoading(_ isLoading: Bool) {
        isLoading ? titleView.titleButton.startLoading() : titleView.titleButton.stopLoading()
    }

    func refreshSiteTitle() {
        let blogName = blog?.settings?.name
        let title = blogName != nil && blogName?.isEmpty == false ? blogName : blog?.displayURL as String?
        titleView.titleButton.setTitle(title, for: .normal)
    }

    @objc func toggleSpotlightOnSiteTitle() {
        titleView.titleButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.siteTitle)
    }

    @objc func toggleSpotlightOnSiteIcon() {
        titleView.siteIconView.spotlightIsShown = QuickStartTourGuide.shared.isCurrentElement(.siteIcon)
    }

    private enum LayoutSpacing {
        static let atSides: CGFloat = 16
        static let top: CGFloat = 16
        static let belowActionRow: CGFloat = 24
        static func betweenTitleViewAndActionRow(_ showsActionRow: Bool) -> CGFloat {
            return showsActionRow ? 32 : 0
        }

        static let spacingBelowIcon: CGFloat = 16
        static let spacingBelowTitle: CGFloat = 8
        static let minimumSideSpacing: CGFloat = 8
        static let interSectionSpacing: CGFloat = 32
        static let buttonsBottomPadding: CGFloat = 40
        static let buttonsSidePadding: CGFloat = 40
        static let maxButtonWidth: CGFloat = 390
        static let siteIconSize = CGSize(width: 48, height: 48)
    }

    // MARK: - Initializers

    required init(items: [ActionRow.Item]) {
        actionRow = ActionRow(items: items)
        titleView = TitleView(frame: .zero)

        super.init(frame: .zero)

        backgroundColor = .appBarBackground

        setupChildViews(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Child View Initialization

    private func setupChildViews(items: [ActionRow.Item]) {
        titleView.siteIconView.tapped = { [weak self] in
            QuickStartTourGuide.shared.visited(.siteIcon)
            self?.titleView.siteIconView.spotlightIsShown = false

            self?.delegate?.siteIconTapped()
        }

        titleView.siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
        }

        titleView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleView)
        addSubview(actionRow)

        addBottomBorder(withColor: .separator)

        let showsActionRow = items.count > 0
        setupConstraintsForChildViews(showsActionRow)
    }

    // MARK: - Constraints

    private var topActionRowConstraint: NSLayoutConstraint?

    private func setupConstraintsForChildViews(_ showsActionRow: Bool) {
        let actionRowConstraints = constraintsForActionRow(showsActionRow)
        let titleViewContraints = constraintsForTitleView()

        NSLayoutConstraint.activate(actionRowConstraints + titleViewContraints)
    }

    private func constraintsForActionRow(_ showsActionRow: Bool) -> [NSLayoutConstraint] {
        let widthConstraint = actionRow.widthAnchor.constraint(equalToConstant: LayoutSpacing.maxButtonWidth)
        widthConstraint.priority = .defaultHigh

        let topActionRowConstraint = actionRow.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: LayoutSpacing.betweenTitleViewAndActionRow(showsActionRow))
        self.topActionRowConstraint = topActionRowConstraint

        return [
            topActionRowConstraint,
            actionRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -LayoutSpacing.belowActionRow),
            actionRow.leadingAnchor.constraint(greaterThanOrEqualTo: titleView.leadingAnchor),
            actionRow.trailingAnchor.constraint(lessThanOrEqualTo: titleView.trailingAnchor),
            actionRow.centerXAnchor.constraint(equalTo: centerXAnchor),
            widthConstraint
        ]
    }

    private func constraintsForTitleView() -> [NSLayoutConstraint] {
        [
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutSpacing.top),
            titleView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: LayoutSpacing.atSides),
            titleView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -LayoutSpacing.atSides)
        ]
    }

    // MARK: - User Action Handlers

    @objc
    private func siteSwitcherTapped() {
        delegate?.siteSwitcherTapped()
    }

    @objc
    private func titleButtonTapped() {
        QuickStartTourGuide.shared.visited(.siteTitle)
        titleView.titleButton.shouldShowSpotlight = false

        delegate?.siteTitleTapped()
    }

    @objc
    private func subtitleButtonTapped() {
        delegate?.visitSiteTapped()
    }

    // MARK: - Accessibility

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        refreshStackViewVisibility()
    }

    private func refreshStackViewVisibility() {
        let showsActionRow = !traitCollection.preferredContentSizeCategory.isAccessibilityCategory

        topActionRowConstraint?.constant = LayoutSpacing.betweenTitleViewAndActionRow(showsActionRow)
    }
}

fileprivate extension NewBlogDetailHeaderView {
    class TitleView: UIView {

        private enum LabelMinimumScaleFactor {
            static let regular: CGFloat = 0.75
            static let accessibility: CGFloat = 0.5
        }

        private enum Dimensions {
            static let siteIconHeight: CGFloat = 64
            static let siteIconWidth: CGFloat = 64
            static let siteSwitcherHeight: CGFloat = 36
            static let siteSwitcherWidth: CGFloat = 36
        }

        private enum LayoutSpacing {
            static let betweenTitleAndSubtitleButtons: CGFloat = 8
            static let betweenSiteIconAndTitle: CGFloat = 16
            static let betweenTitleAndSiteSwitcher: CGFloat = 16
            static let betweenSiteSwitcherAndRightPadding: CGFloat = 4
            static let subtitleButtonImageInsets = UIEdgeInsets(top: 1, left: 4, bottom: 0, right: 0)
            static let rtlSubtitleButtonImageInsets = UIEdgeInsets(top: 1, left: -4, bottom: 0, right: 4)
        }

        // MARK: - Child Views

        private lazy var mainStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                siteIconView,
                titleStackView,
                siteSwitcherButton
            ])

            stackView.alignment = .center
            stackView.spacing = LayoutSpacing.betweenSiteIconAndTitle
            stackView.translatesAutoresizingMaskIntoConstraints = false

            return stackView
        }()

        let siteIconView: SiteIconView = {
            let siteIconView = SiteIconView(frame: .zero)
            siteIconView.translatesAutoresizingMaskIntoConstraints = false
            return siteIconView
        }()

        let subtitleButton: UIButton = {
            let button = UIButton()

            button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.footnote)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.regular
            button.titleLabel?.lineBreakMode = .byTruncatingTail

            button.setTitleColor(.primary, for: .normal)
            button.accessibilityHint = NSLocalizedString("Tap to view your site", comment: "Accessibility hint for button used to view the user's site")

            if let pointSize = button.titleLabel?.font.pointSize {
                button.setImage(UIImage.gridicon(.external, size: CGSize(width: pointSize, height: pointSize)), for: .normal)
            }

            // Align the image to the right
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                button.semanticContentAttribute = .forceLeftToRight
                button.imageEdgeInsets = LayoutSpacing.rtlSubtitleButtonImageInsets
            } else {
                button.semanticContentAttribute = .forceRightToLeft
                button.imageEdgeInsets = LayoutSpacing.subtitleButtonImageInsets
            }

            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(subtitleButtonTapped), for: .touchUpInside)

            return button
        }()

        let titleButton: SpotlightableButton = {
            let button = SpotlightableButton(type: .custom)
            button.contentHorizontalAlignment = .leading
            button.titleLabel?.font = AppStyleGuide.blogDetailHeaderTitleFont
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.regular
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.titleLabel?.numberOfLines = 1

            button.accessibilityHint = NSLocalizedString("Tap to change the site's title", comment: "Accessibility hint for button used to change site title")

            // I don't understand why this is needed, but without it the button has additional
            // vertical padding, so it's more difficult to get the spacing we want.
            button.setImage(UIImage(), for: .normal)

            button.setTitleColor(.text, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
            return button
        }()

        let siteSwitcherButton: UIButton = {
            let button = UIButton(frame: .zero)
            let image = UIImage.gridicon(.chevronDown)

            button.setImage(image, for: .normal)
            button.contentMode = .center
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = .gray
            button.accessibilityLabel = NSLocalizedString("Switch Site", comment: "Button used to switch site")
            button.accessibilityHint = NSLocalizedString("Tap to switch to another site, or add a new site", comment: "Accessibility hint for button used to switch site")
            button.accessibilityIdentifier = "SwitchSiteButton"

            button.addTarget(self, action: #selector(siteSwitcherTapped), for: .touchUpInside)

            return button
        }()

        private(set) lazy var titleStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                titleButton,
                subtitleButton
            ])

            stackView.alignment = .leading
            stackView.distribution = .equalSpacing
            stackView.axis = .vertical
            stackView.spacing = LayoutSpacing.betweenTitleAndSubtitleButtons
            stackView.translatesAutoresizingMaskIntoConstraints = false

            return stackView
        }()

        // MARK: - Initializers

        override init(frame: CGRect) {
            super.init(frame: frame)

            setupChildViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Configuration

        func set(url: String) {
            subtitleButton.setTitle(url, for: .normal)
        }

        // MARK: - Accessibility

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)

            refreshMainStackViewAxis()
        }

        // MARK: - Child View Setup

        private func setupChildViews() {
            refreshMainStackViewAxis()
            addSubview(mainStackView)
            pinSubviewToAllEdges(mainStackView)
            setupConstraintsForSiteSwitcher()
        }

        private func refreshMainStackViewAxis() {
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                mainStackView.axis = .vertical

                titleButton.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.accessibility
                subtitleButton.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.accessibility
            } else {
                mainStackView.axis = .horizontal

                titleButton.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.regular
                subtitleButton.titleLabel?.minimumScaleFactor = LabelMinimumScaleFactor.regular
            }
        }

        // MARK: - Constraints

        private func setupConstraintsForSiteSwitcher() {
            NSLayoutConstraint.activate([
                siteSwitcherButton.heightAnchor.constraint(equalToConstant: Dimensions.siteSwitcherHeight),
                siteSwitcherButton.widthAnchor.constraint(equalToConstant: Dimensions.siteSwitcherWidth)
            ])
        }
    }
}
