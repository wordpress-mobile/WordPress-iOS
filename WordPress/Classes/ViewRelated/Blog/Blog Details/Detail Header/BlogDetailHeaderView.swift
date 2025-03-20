import Gridicons
import UIKit
import DesignSystem
import SwiftUI
import WordPressUI

@objc protocol BlogDetailHeaderViewDelegate {
    func makeSiteIconMenu() -> UIMenu?
    func makeSiteActionsMenu() -> UIMenu?
    func siteIconReceivedDroppedImage(_ image: UIImage?)
    func siteIconShouldAllowDroppedImages() -> Bool
    func siteTitleTapped()
    func siteSwitcherTapped(sourceView: UIView)
    func buttonShareSiteTapped()
    func visitSiteTapped()
}

class BlogDetailHeaderView: UIView {

    // MARK: - Child Views

    let titleView: TitleView

    // MARK: - Delegate

    @objc weak var delegate: BlogDetailHeaderViewDelegate?

    @objc var updatingIcon: Bool = false {
        didSet {
            titleView.siteIconView.imageView.isHidden = updatingIcon
            if updatingIcon {
                titleView.siteIconView.activityIndicator.startAnimating()
            } else {
                titleView.siteIconView.activityIndicator.stopAnimating()
            }
        }
    }

    @objc var blavatarImageView: UIView {
        return titleView.siteIconView.imageView
    }

    @objc var blog: Blog? {
        didSet {
            refreshIconImage()
            refreshSiteTitle()

            if let displayURL = blog?.displayURL as String? {
                titleView.set(url: displayURL)
            }

            titleView.siteIconView.allowsDropInteraction = delegate?.siteIconShouldAllowDroppedImages() == true
        }
    }

    @objc func refreshIconImage() {
        guard let blog else { return }

        let viewModel = SiteIconViewModel(blog: blog)
        titleView.siteIconView.imageView.setIcon(with: viewModel)
    }

    func setTitleLoading(_ isLoading: Bool) {
        titleView.alpha = isLoading ? 0.5 : 1.0
        titleView.isUserInteractionEnabled = !isLoading
    }

    func refreshSiteTitle() {
        let blogName = blog?.settings?.name
        let title = blogName != nil && blogName?.isEmpty == false ? blogName : blog?.displayURL as String?
        titleView.titleButton.setTitle(title, for: .normal)
    }

    private enum LayoutSpacing {
        static let atSides: CGFloat = 20
        static let top: CGFloat = 10
        static let bottom: CGFloat = 16
    }

    private let isSidebarModeEnabled: Bool

    // MARK: - Initializers

    required init(delegate: BlogDetailHeaderViewDelegate, isSidebarModeEnabled: Bool) {
        titleView = TitleView(isSidebarModeEnabled: isSidebarModeEnabled)
        self.isSidebarModeEnabled = isSidebarModeEnabled

        super.init(frame: .zero)

        self.delegate = delegate
        setupChildViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Child View Initialization

    private func setupChildViews() {
        assert(delegate != nil)

        if let siteActionsMenu = delegate?.makeSiteActionsMenu() {
            titleView.siteSwitcherButton.menu = siteActionsMenu
            titleView.siteSwitcherButton.addTarget(self, action: #selector(siteSwitcherTapped), for: .primaryActionTriggered)
            titleView.siteSwitcherButton.addAction(UIAction { _ in
                WPAnalytics.trackEvent(.mySiteHeaderMoreTapped)
            }, for: .menuActionTriggered)
        }

        if let siteIconMenu = delegate?.makeSiteIconMenu() {
            titleView.siteIconView.setMenu(siteIconMenu) {
                WPAnalytics.track(.siteSettingsSiteIconTapped)
            }
        }

        titleView.siteIconView.dropped = { [weak self] images in
            self?.delegate?.siteIconReceivedDroppedImage(images.first)
        }

        titleView.subtitleButton.menu = makeSiteLinkMenu()
        titleView.subtitleButton.addTarget(self, action: #selector(subtitleButtonTapped), for: .touchUpInside)
        titleView.titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)

        titleView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleView)

        setupConstraintsForChildViews()
    }

    private func makeSiteLinkMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: SharedStrings.Button.share, image: UIImage(systemName: "square.and.arrow.up"), handler: { [weak self] _ in
                self?.delegate?.buttonShareSiteTapped()
            }),
            UIAction(title: Strings.visitSite, image: UIImage(systemName: "safari"), handler: { [weak self] _ in
                self?.delegate?.visitSiteTapped()
            }),
            UIAction(title: SharedStrings.Button.copyLink, image: UIImage(systemName: "doc.on.doc"), handler: { [weak self] _ in
                UIPasteboard.general.url = URL(string: (self?.blog?.displayURL ?? "") as String)
            })
        ])
    }

    // MARK: - Constraints

    private func setupConstraintsForChildViews() {
        let constraints = constraintsForTitleView()
        NSLayoutConstraint.activate(constraints)
    }

    private func constraintsForTitleView() -> [NSLayoutConstraint] {
        return [
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: isSidebarModeEnabled ? 3 : LayoutSpacing.top),
            titleView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: LayoutSpacing.atSides),
            titleView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            titleView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    // MARK: - User Action Handlers

    @objc
    private func siteSwitcherTapped(_ sender: UIButton) {
        delegate?.siteSwitcherTapped(sourceView: sender)
    }

    @objc
    private func titleButtonTapped() {
        delegate?.siteTitleTapped()
    }

    @objc
    private func subtitleButtonTapped() {
        delegate?.visitSiteTapped()
    }
}

extension BlogDetailHeaderView {
    class TitleView: UIView {
        private enum Dimensions {
            static let siteSwitcherHeight: CGFloat = 44
            static let siteSwitcherWidth: CGFloat = 44
        }

        // MARK: - Child Views

        private lazy var mainStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                siteIconView,
                titleStackView,
                siteSwitcherButton
            ])

            stackView.alignment = .center
            stackView.spacing = isSidebarModeEnabled ? 20 : 12
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.setCustomSpacing(2, after: titleStackView)

            return stackView
        }()

        let siteIconView: SiteDetailsSiteIconView = {
            let siteIconView = SiteDetailsSiteIconView(frame: .zero)
            siteIconView.translatesAutoresizingMaskIntoConstraints = false
            return siteIconView
        }()

        private(set) lazy var subtitleButton: UIButton = {
            let button = UIButton(type: .custom)

            var configuration = UIButton.Configuration.plain()
            configuration.titleTextAttributesTransformer = .init { attributes in
                var attributes = attributes
                attributes.font = WPStyleGuide.fontForTextStyle(.subheadline)
                attributes.foregroundColor = .primary
                return attributes
            }
            configuration.contentInsets = isSidebarModeEnabled ? NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0) : NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 1, trailing: 0)
            configuration.titleLineBreakMode = .byTruncatingTail
            button.configuration = configuration
            button.accessibilityHint = NSLocalizedString("Tap to view your site", comment: "Accessibility hint for button used to view the user's site")
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private(set) lazy var titleButton: UIButton = {
            let button = UIButton(type: .custom)

            var configuration = UIButton.Configuration.plain()
            configuration.titleTextAttributesTransformer = .init { [weak self] attributes in
                guard let self else { return attributes }
                var attributes = attributes
                let font = isSidebarModeEnabled ? AppStyleGuide.current.navigationBarLargeFont : WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
                attributes.font = font
                attributes.foregroundColor = UIColor.label
                return attributes
            }
            configuration.contentInsets = isSidebarModeEnabled ? .zero : NSDirectionalEdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0)
            configuration.titleLineBreakMode = .byTruncatingTail
            button.configuration = configuration

            button.accessibilityHint = NSLocalizedString("Tap to change the site's title", comment: "Accessibility hint for button used to change site title")
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityIdentifier = .siteTitleAccessibilityId
            return button
        }()

        let siteSwitcherButton: UIButton = {
            var configuration = UIButton.Configuration.plain()
            configuration.image = UIImage(systemName: "chevron.down.circle.fill")?.withBaselineOffset(fromBottom: 4)
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
                .applying(UIImage.SymbolConfiguration(font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)))
            configuration.baseForegroundColor = .label

            let button = UIButton(configuration: configuration)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityLabel = NSLocalizedString("mySite.siteActions.button", value: "Site Actions", comment: "Button that reveals more site actions")
            button.accessibilityHint = NSLocalizedString("mySite.siteActions.hint", value: "Tap to show more site actions", comment: "Accessibility hint for button used to show more site actions")
            button.accessibilityIdentifier = .switchSiteAccessibilityId

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

        private let isSidebarModeEnabled: Bool

        // MARK: - Initializers

        init(isSidebarModeEnabled: Bool) {
            self.isSidebarModeEnabled = isSidebarModeEnabled
            super.init(frame: .zero)

            setupChildViews()
            if isSidebarModeEnabled {
                configureLargeTitleMode()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Configuration

        fileprivate func configureLargeTitleMode() {
            siteIconView.setImageViewSize(50)

            siteIconView.transform = CGAffineTransform(translationX: 0, y: 2) // Visually center vertically

            siteSwitcherButton.removeFromSuperview()
            mainStackView.addSubview(siteSwitcherButton)
            NSLayoutConstraint.activate([
                siteSwitcherButton.lastBaselineAnchor.constraint(equalTo: titleButton.lastBaselineAnchor, constant: -2),
                siteSwitcherButton.leadingAnchor.constraint(equalTo: titleButton.trailingAnchor, constant: 2)
            ])
        }

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
                mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: isSidebarModeEnabled ? 0 : .DS.Padding.double),
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
                siteSwitcherButton.heightAnchor.constraint(equalToConstant: Dimensions.siteSwitcherHeight),
                siteSwitcherButton.widthAnchor.constraint(equalToConstant: Dimensions.siteSwitcherWidth)
            ])
        }
    }
}

private extension String {
    // MARK: Accessibility Identifiers
    static let siteTitleAccessibilityId = "site-title-button"
    static let siteUrlAccessibilityId = "site-url-button"
    static let switchSiteAccessibilityId = "switch-site-button"
}

private enum Strings {
    static let visitSite = NSLocalizedString("blogHeader.actionVisitSite", value: "Visit Site", comment: "Context menu button title")
}
