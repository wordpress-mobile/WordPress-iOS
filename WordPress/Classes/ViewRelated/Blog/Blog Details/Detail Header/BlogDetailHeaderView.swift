import Gridicons
import UIKit

@objc protocol BlogDetailHeaderViewDelegate {
    func makeSiteIconMenu() -> UIMenu?
    func makeSiteActionsMenu() -> UIMenu?
    func didShowSiteIconMenu()
    func siteIconReceivedDroppedImage(_ image: UIImage?)
    func siteIconShouldAllowDroppedImages() -> Bool
    func siteTitleTapped()
    func siteSwitcherTapped()
    func visitSiteTapped()
}

class BlogDetailHeaderView: UIView {

    // MARK: - Child Views

    let titleView: TitleView

    // MARK: - Delegate

    @objc weak var delegate: BlogDetailHeaderViewDelegate?

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
            toggleSpotlightOnSiteUrl()
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

    func toggleSpotlightOnSiteTitle() {
        titleView.titleButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.siteTitle)
    }

    func toggleSpotlightOnSiteUrl() {
        titleView.subtitleButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.viewSite)
    }

    func toggleSpotlightOnSiteIcon() {
        titleView.siteIconView.spotlightIsShown = QuickStartTourGuide.shared.isCurrentElement(.siteIcon)
    }

    private enum LayoutSpacing {
        static let atSides: CGFloat = 20
        static let top: CGFloat = 10
        static let bottom: CGFloat = 16
        static func betweenTitleViewAndActionRow(_ showsActionRow: Bool) -> CGFloat {
            return showsActionRow ? 32 : 0
        }
    }

    // MARK: - Initializers

    required init(items: [ActionRow.Item], delegate: BlogDetailHeaderViewDelegate) {
        titleView = TitleView(frame: .zero)

        super.init(frame: .zero)

        self.delegate = delegate
        setupChildViews(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Child View Initialization

    private func setupChildViews(items: [ActionRow.Item]) {
        assert(delegate != nil)

        if let siteActionsMenu = delegate?.makeSiteActionsMenu() {
            titleView.siteActionButton.showsMenuAsPrimaryAction = true
            titleView.siteActionButton.menu = siteActionsMenu
            titleView.siteActionButton.addAction(UIAction { _ in
                WPAnalytics.trackEvent(.mySiteHeaderMoreTapped)
            }, for: .menuActionTriggered)
        }

        if let siteIconMenu = delegate?.makeSiteIconMenu() {
            titleView.siteIconView.setMenu(siteIconMenu) { [weak self] in
                self?.delegate?.didShowSiteIconMenu()
                WPAnalytics.track(.siteSettingsSiteIconTapped)
                self?.titleView.siteIconView.spotlightIsShown = false
            }
        }

        titleView.siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
        }

        titleView.subtitleButton.addTarget(self, action: #selector(subtitleButtonTapped), for: .touchUpInside)
        titleView.titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)

        titleView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleView)

        let showsActionRow = items.count > 0
        setupConstraintsForChildViews(showsActionRow)
    }

    // MARK: - Constraints

    private var topActionRowConstraint: NSLayoutConstraint?

    private func setupConstraintsForChildViews(_ showsActionRow: Bool) {
        let constraints = constraintsForTitleView()

        NSLayoutConstraint.activate(constraints)
    }

    private func constraintsForTitleView() -> [NSLayoutConstraint] {
        return [
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutSpacing.top),
            titleView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: LayoutSpacing.atSides),
            titleView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -LayoutSpacing.atSides),
            titleView.bottomAnchor.constraint(equalTo: bottomAnchor)
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

extension BlogDetailHeaderView {
    class TitleView: UIView {
        private enum Dimensions {
            static let siteSwitcherHeight: CGFloat = 36
            static let siteSwitcherWidth: CGFloat = 32
        }

        // MARK: - Child Views

        private lazy var mainStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                siteIconView,
                titleStackView,
                siteActionButton
            ])

            stackView.alignment = .center
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.setCustomSpacing(4, after: titleStackView)

            return stackView
        }()

        let siteIconView: SiteIconView = {
            let siteIconView = SiteIconView(frame: .zero)
            siteIconView.translatesAutoresizingMaskIntoConstraints = false
            return siteIconView
        }()

        let subtitleButton: SpotlightableButton = {
            let button = SpotlightableButton(type: .custom)

            var configuration = UIButton.Configuration.plain()
            configuration.titleTextAttributesTransformer = .init { attributes in
                var attributes = attributes
                attributes.font = WPStyleGuide.fontForTextStyle(.subheadline)
                attributes.foregroundColor = .primary
                return attributes
            }
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 1, trailing: 0)
            configuration.titleLineBreakMode = .byTruncatingTail
            button.configuration = configuration

            button.menu = UIMenu(children: [
                UIAction(title: Strings.visitSite, image: UIImage(systemName: "safari"), handler: { [weak button] _ in
                    button?.sendActions(for: .touchUpInside)
                }),
                UIAction(title: Strings.actionCopyURL, image: UIImage(systemName: "doc.on.doc"), handler: { [weak button] _ in
                    UIPasteboard.general.url = URL(string: button?.titleLabel?.text ?? "")
                })
            ])

            button.accessibilityHint = NSLocalizedString("Tap to view your site", comment: "Accessibility hint for button used to view the user's site")
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        let titleButton: SpotlightableButton = {
            let button = SpotlightableButton(type: .custom)
            button.spotlightHorizontalPosition = .trailing

            var configuration = UIButton.Configuration.plain()
            configuration.titleTextAttributesTransformer = .init { attributes in
                var attributes = attributes
                attributes.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
                attributes.foregroundColor = UIColor.label
                return attributes
            }
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0)
            configuration.titleLineBreakMode = .byTruncatingTail
            button.configuration = configuration

            button.accessibilityHint = NSLocalizedString("Tap to change the site's title", comment: "Accessibility hint for button used to change site title")
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityIdentifier = .siteTitleAccessibilityId
            return button
        }()

        let siteActionButton: UIButton = {
            let button = UIButton(frame: .zero)
            let image = UIImage(named: "more-horizontal-mobile")?.withRenderingMode(.alwaysTemplate)

            button.setImage(image, for: .normal)
            button.contentMode = .center
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = .secondaryLabel
            button.accessibilityLabel = NSLocalizedString("mySite.siteActions.button", value: "Site Actions", comment: "Button that reveals more site actions")
            button.accessibilityHint = NSLocalizedString("mySite.siteActions.hint", value: "Tap to show more site actions", comment: "Accessibility hint for button used to show more site actions")
            button.accessibilityIdentifier = .siteActionAccessibilityId

            return button
        }()

        private(set) lazy var titleStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                titleButton,
                subtitleButton
            ])

            stackView.alignment = .leading
            stackView.axis = .vertical
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
            subtitleButton.accessibilityIdentifier = .siteUrlAccessibilityId
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

            NSLayoutConstraint.activate([
                mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: Length.Padding.double),
                mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
            ])

            setupConstraintsForSiteSwitcher()
        }

        private func refreshMainStackViewAxis() {
            mainStackView.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        }

        // MARK: - Constraints

        private func setupConstraintsForSiteSwitcher() {
            NSLayoutConstraint.activate([
                siteActionButton.heightAnchor.constraint(equalToConstant: Dimensions.siteSwitcherHeight),
                siteActionButton.widthAnchor.constraint(equalToConstant: Dimensions.siteSwitcherWidth)
            ])
        }
    }
}

private extension String {
    // MARK: Accessibility Identifiers
    static let siteTitleAccessibilityId = "site-title-button"
    static let siteUrlAccessibilityId = "site-url-button"
    static let siteActionAccessibilityId = "site-action-button"
}

private enum Strings {
    static let visitSite = NSLocalizedString("blogHeader.actionVisitSite", value: "Visit site", comment: "Context menu button title")
    static let actionCopyURL = NSLocalizedString("blogHeader.actionCopyURL", value: "Copy URL", comment: "Context menu button title")

}
