import UIKit
import Combine
import SwiftUI
import WordPressAuthenticator
import WordPressUI

/// The presenter that uses triple-column navigation for `.regular` size classes
/// and a tab-bar based navigation for `.compact` size class.
final class SplitViewRootPresenter: RootViewPresenter {
    private let sidebarViewModel = SidebarViewModel()
    private let splitVC = UISplitViewController(style: .tripleColumn)
    private let tabBarViewController: WPTabBarController
    private weak var sitePickerPopoverVC: UIViewController?
    private var cancellables: [AnyCancellable] = []

    private var siteContent: SiteSplitViewContent?
    private var notificationsContent: NotificationsSplitViewContent?
    private var readerContent: ReaderSplitViewContent?
    private var welcomeContent: WelcomeSplitViewContent?

    private var displayingContent: SplitViewDisplayable? {
        let possibleContent: [SplitViewDisplayable?] = [siteContent, notificationsContent, readerContent, welcomeContent]
        let displaying = possibleContent
            .compactMap { $0 }
            .filter { $0.isDisplaying(in: splitVC) }

        wpAssert(displaying.count <= 1)

        return displaying.first
    }

    /// Is the app displaying tab bar UI instead of the full split view UI (with sidebar).
    private var isDisplayingTabBar: Bool {
        if splitVC.isCollapsed {
            wpAssert(splitVC.viewController(for: .compact) == tabBarViewController, "Split view is collapsed, but is not displaying the tab bar view controller")
            return true
        }

        return false
    }

    init() {
        tabBarViewController = WPTabBarController(staticScreens: false)

        splitVC.delegate = self

        let sidebarVC = SidebarViewController(viewModel: sidebarViewModel)
        let navigationVC = makeRootNavigationController(with: sidebarVC)
        splitVC.setViewController(navigationVC, for: .primary)

        splitVC.setViewController(tabBarViewController, for: .compact)

        NotificationCenter.default.publisher(for: MySiteViewController.didPickSiteNotification).sink { [weak self] in
            guard let site = $0.userInfo?[MySiteViewController.siteUserInfoKey] as? Blog else {
                return wpAssertionFailure("invalid notification")
            }
            self?.sidebarViewModel.selection = .blog(TaggedManagedObjectID(site))
        }.store(in: &cancellables)

        sidebarViewModel.$selection.compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] in self?.configure(for: $0) }
            .store(in: &cancellables)

        sidebarViewModel.navigate = { [weak self] in
            self?.navigate(to: $0)
        }

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: ContextManager.shared.mainContext)
            .sink { [weak self] in
                self?.handleCoreDataChanges($0)
            }
            .store(in: &cancellables)
    }

    private func configure(for selection: SidebarSelection) {
        switch selection {
        case .blog, .reader:
            splitVC.preferredSupplementaryColumnWidth = 320
        default:
            splitVC.preferredSupplementaryColumnWidth = UISplitViewController.automaticDimension
        }

        let content: SplitViewDisplayable
        switch selection {
        case .welcome:
            if let welcomeContent {
                content = welcomeContent
            } else {
                welcomeContent = WelcomeSplitViewContent { [weak self] in self?.navigate(to: .addSite(selection: $0)) }
                content = welcomeContent!
            }
        case .blog(let objectID):
            if let siteContent, siteContent.blog.objectID == objectID.objectID {
                content = siteContent
            } else {
                do {
                    let site = try ContextManager.shared.mainContext.existingObject(with: objectID)
                    siteContent = SiteSplitViewContent(blog: site)
                    content = siteContent!
                } catch {
                    // TODO: (wpsidebar) switch to a different blog?
                    return
                }
            }
        case .notifications:
            // TODO: (wpsidebar) update tab bar item when new notifications arrive
            if let notificationsContent {
                content = notificationsContent
            } else {
                notificationsContent = NotificationsSplitViewContent()
                content = notificationsContent!
            }
        case .reader:
            if let readerContent {
                content = readerContent
            } else {
                readerContent = ReaderSplitViewContent()
                content = readerContent!
            }
        }

        display(content: content)

        DispatchQueue.main.async {
            self.splitVC.hide(.primary)
        }
    }

    private func makeRootNavigationController(with viewController: UIViewController) -> UINavigationController {
        let navigationVC = UINavigationController(rootViewController: viewController)
        viewController.navigationItem.largeTitleDisplayMode = .automatic
        navigationVC.navigationBar.prefersLargeTitles = true
        return navigationVC
    }

    private func navigate(to step: SidebarNavigationStep) {
        switch step {
        case .allSites(let sourceRect):
            showSitePicker(sourceRect: sourceRect)
        case .addSite(let selection):
            showAddSiteScreen(selection: selection)
        case .domains:
#if IS_JETPACK
            let domainsVC = AllDomainsListViewController()
            let navigationVC = UINavigationController(rootViewController: domainsVC)
            navigationVC.modalPresentationStyle = .formSheet
            splitVC.present(navigationVC, animated: true)
#endif

#if IS_WORDPRESS
            wpAssertionFailure("domains are not supported in wpios")
#endif
        case .help:
            let supportVC = SupportTableViewController()
            let navigationVC = UINavigationController(rootViewController: supportVC)
            navigationVC.modalPresentationStyle = .formSheet
            splitVC.present(navigationVC, animated: true)
        case .profile:
            showMeScreen(completion: nil)
        case .signIn:
            Task {
                await self.signIn()
            }
        }
    }

    private func showSitePicker(sourceRect: CGRect) {
        let sitePickerVC = SiteSwitcherViewController(
            configuration: BlogListConfiguration(shouldHideRecentSites: true),
            addSiteAction: { [weak self] in
                self?.showAddSiteScreen(selection: $0)
            },
            onSiteSelected: { [weak self] site in
                self?.splitVC.dismiss(animated: true)
                RecentSitesService().touch(blog: site)
                self?.sidebarViewModel.selection = .blog(TaggedManagedObjectID(site))
            }
        )
        let navigationVC = UINavigationController(rootViewController: sitePickerVC)
        navigationVC.modalPresentationStyle = .popover
        navigationVC.popoverPresentationController?.sourceView = splitVC.view
        navigationVC.popoverPresentationController?.sourceRect = sourceRect
        // Show no arrow and simply overlay the sidebar
        navigationVC.popoverPresentationController?.permittedArrowDirections = [.left]
        sitePickerPopoverVC = navigationVC
        self.splitVC.present(navigationVC, animated: true)
        WPAnalytics.track(.sidebarAllSitesTapped)
    }

    private func showAddSiteScreen(selection: AddSiteMenuViewModel.Selection) {
        AddSiteController(viewController: splitVC.presentedViewController ?? splitVC, source: "sidebar")
            .showSiteCreationScreen(selection: selection)
    }

    @MainActor private func signIn() async {
        WPAnalytics.track(.wpcomWebSignIn, properties: ["source": "sidebar", "stage": "start"])

        let token: String
        do {
            token = try await WordPressDotComAuthenticator().authenticate(from: splitVC)
        } catch {
            WPAnalytics.track(.wpcomWebSignIn, properties: ["source": "sidebar", "stage": "error", "error": "\(error)"])
            return
        }

        WPAnalytics.track(.wpcomWebSignIn, properties: ["source": "sidebar", "stage": "success"])

        SVProgressHUD.show()
        let credentials = WordPressComCredentials(authToken: token, isJetpackLogin: false, multifactor: false)
        WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wpcom: credentials)) {
            SVProgressHUD.dismiss()
        }
    }

    private func handleCoreDataChanges(_ notification: Foundation.Notification) {
        // Automatically switch to a site or show the sign in screen, when the current blog is removed.

        guard let blog = self.currentlyVisibleBlog(),
              let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
              deleted.contains(blog)
        else {
            return
        }

        if let newSite = Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext) {
            self.sidebarViewModel.selection = .blog(TaggedManagedObjectID(newSite))
        } else {
            self.sidebarViewModel.selection = .welcome
            WordPressAppDelegate.shared?.windowManager.showSignInUI()
        }
    }

    // MARK: – RootViewPresenter

    // MARK: RootViewPresenter (General)

    var rootViewController: UIViewController { splitVC }

    func currentlySelectedScreen() -> String {
        if splitVC.isCollapsed {
            return tabBarViewController.currentlySelectedScreen()
        } else {
            switch sidebarViewModel.selection {
            case .welcome: return "Welcome"
            case .blog: return WPTabBarCurrentlySelectedScreenSites
            case .notifications: return WPTabBarCurrentlySelectedScreenNotifications
            case .reader: return WPTabBarCurrentlySelectedScreenReader
            default: return ""
            }
        }
    }

    // MARK: RootViewPresenter (Sites)

    func currentlyVisibleBlog() -> Blog? {
        assert(Thread.isMainThread)
        return siteContent?.blog
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any]) {
        if splitVC.isCollapsed {
            tabBarViewController.showBlogDetails(for: blog, then: subsection, userInfo: userInfo)
        } else {
            sidebarViewModel.selection = .blog(TaggedManagedObjectID(blog))
            if let subsection {
                wpAssert(siteContent != nil, "failed to open blog subsection")
                siteContent?.showSubsection(subsection, userInfo: userInfo)
            }
        }
    }

    func showMySitesTab() {
        guard let blog = currentlyVisibleBlog() else { return }
        sidebarViewModel.selection = .blog(TaggedManagedObjectID(blog))
    }

    // MARK: RootViewPresenter (Reader)

    func showReaderTab() {
        sidebarViewModel.selection = .reader
    }

    func showReaderTab(forPost: NSNumber, onBlog: NSNumber) {
        fatalError()
    }

    func switchToDiscover() {
        fatalError()
    }

    func navigateToReaderSearch() {
        fatalError()
    }

    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        fatalError()
    }

    func switchToMyLikes() {
        fatalError()
    }

    func switchToFollowedSites() {
        fatalError()
    }

    func navigateToReaderSite(_ topic: ReaderSiteTopic) {
        fatalError()
    }

    func navigateToReaderTag(_ tagSlug: String) {
        fatalError()
    }

    func navigateToReader(_ pushControlller: UIViewController?) {
        fatalError()
    }

    // MARK: Notifications

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        sidebarViewModel.selection = .notifications

        if let notifications = self.notificationsContent {
            completion?(notifications.notificationsViewController)
        }
    }

    // MARK: Me

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        if isDisplayingTabBar {
            tabBarViewController.showMeScreen(completion: completion)
            return
        }

        let meVC = MeViewController()
        meVC.isSidebarModeEnabled = true
        meVC.navigationItem.rightBarButtonItem = {
            let button = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: .init { [weak self] _ in
                self?.splitVC.dismiss(animated: true)
            })
            button.setTitleTextAttributes([.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)], for: .normal)
            return button
        }()

        let navigationVC = UINavigationController(rootViewController: meVC)
        navigationVC.modalPresentationStyle = .formSheet
        splitVC.present(navigationVC, animated: true) {
            completion?(meVC)
        }
    }
}

extension SplitViewRootPresenter: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
        if column == .primary {
            sitePickerPopoverVC?.presentingViewController?.dismiss(animated: true)
        }
    }
}

// MARK: - Content displayed within the split view, alongside the sidebar

/// This protocol is an abstraction of the `supplementary` and `secondary` columns in a split view.
///
/// When in full-screen mode, `SplitViewRootPresenter` presents a triple-column split view. The sidebar is displayed in
/// the primary column, which is always accessible. The `supplementary` and `secondary` columns display different
/// content, depending on what users choose from the sidebar.
protocol SplitViewDisplayable: AnyObject {
    var supplementary: UINavigationController { get }
    var secondary: UINavigationController { get set }

    func displayed(in splitVC: UISplitViewController)
}

extension SplitViewDisplayable {
    func isDisplaying(in splitVC: UISplitViewController) -> Bool {
        splitVC.viewController(for: .supplementary) === self.supplementary
    }

    func refresh(with splitVC: UISplitViewController) {
        guard isDisplaying(in: splitVC) else { return }
        guard let currentContent = splitVC.viewController(for: .secondary) as? UINavigationController else { return }

        self.secondary = currentContent
    }
}

private extension SplitViewRootPresenter {
    func display(content: SplitViewDisplayable) {
        displayingContent?.refresh(with: splitVC)

        splitVC.setViewController(content.supplementary, for: .supplementary)
        splitVC.setViewController(content.secondary, for: .secondary)

        content.displayed(in: splitVC)
    }
}
