import UIKit
import Combine
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

    private var displayingContent: SplitViewDisplayable? {
        let possibleContent: [SplitViewDisplayable?] = [siteContent, notificationsContent, readerContent]
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
        // TODO: (wpsidebar) refactor
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

        sidebarViewModel.$selection.compactMap { $0 }.sink { [weak self] in
            self?.configure(for: $0)
        }.store(in: &cancellables)

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
        // Do not re-apply the sidebar selection.
        guard displayingContent?.selection != selection else {
            return
        }

        switch selection {
        case .blog, .reader:
            splitVC.preferredSupplementaryColumnWidth = 320
        default:
            splitVC.preferredSupplementaryColumnWidth = UISplitViewController.automaticDimension
        }

        switch selection {
        case .empty:
            // TODO: (wpsidebar) add support for the "no sites" scenario
            break
        case .blog(let objectID):
            do {
                let site = try ContextManager.shared.mainContext.existingObject(with: objectID)
                showDetails(for: site)
            } catch {
                // TODO: (wpsidebar) show empty state
            }
        case .notifications:
            showNotificationsTab(completion: nil)
        case .reader:
            showReaderTab()
        }

        splitVC.hide(.primary)
    }

    private func showDetails(for site: Blog) {
        if let siteContent, siteContent.blog == site {
            display(content: siteContent)
        } else {
            let siteContent = SiteSplitViewContent(blog: site)
            self.siteContent = siteContent
            display(content: siteContent)
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
            self.sidebarViewModel.selection = .empty
            WordPressAppDelegate.shared?.windowManager.showSignInUI()
        }
    }

    // MARK: – RootViewPresenter

    var rootViewController: UIViewController { splitVC }

    var currentViewController: UIViewController?

    func showBlogDetails(for blog: Blog) {
        sidebarViewModel.selection = .blog(TaggedManagedObjectID(blog))
    }

    func getMeScenePresenter() -> any ScenePresenter {
        fatalError()
    }

    func currentlySelectedScreen() -> String {
        ""
    }

    // TODO: (wpsidebar) Can we remove it?
    func currentlyVisibleBlog() -> Blog? {
        assert(Thread.isMainThread)

        return siteContent?.blog
    }

    func willDisplayPostSignupFlow() {
        fatalError()
    }

    var readerTabViewController: ReaderTabViewController?

    var readerCoordinator: ReaderCoordinator?

    var readerNavigationController: UINavigationController?

    func showReaderTab() {
        if let readerContent {
            display(content: readerContent)
        } else {
            let readerContent = ReaderSplitViewContent()
            self.readerContent = readerContent
            display(content: readerContent)
        }
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

    var mySitesCoordinator: MySitesCoordinator

    func showMySitesTab() {
        if let siteContent {
            display(content: siteContent)
        } else if let blog = Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext) {
            showDetails(for: blog)
        } else {
            // TODO: show empty?
        }
    }

    func showPages(for blog: Blog) {
        fatalError()
    }

    func showPosts(for blog: Blog) {
        fatalError()
    }

    func showMedia(for blog: Blog) {
        fatalError()
    }

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        // TODO: (wpsidebar) update tab bar item when new notifications arrive
        let notifications: NotificationsSplitViewContent
        if let existing = self.notificationsContent {
            notifications = existing
        } else {
            notifications = .init()
            self.notificationsContent = notifications
        }

        display(content: notifications)

        completion?(notifications.notificationsViewController)
    }

    var meViewController: MeViewController?

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

    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {
        if column == .primary, let selection = displayingContent?.selection, selection != sidebarViewModel.selection {
            sidebarViewModel.selection = selection
        }
    }
}

// MARK: - Content displayed within the split view, alongside the sidebar

/// This protocol is an abstraction of the `supplimentary` and `secondary` columns in a split view.
///
/// When in full-screen mode, `SplitViewRootPresenter` presents a triple-column split view. The sidebar is displayed in
/// the primary column, which is always accessible. The `supplimentary` and `secondary` columns display different
/// content, depending on what users choose from the sidebar.
protocol SplitViewDisplayable: AnyObject {
    var supplimentary: UINavigationController { get }
    var secondary: UINavigationController? { get set }

    func displayed(in splitVC: UISplitViewController)

    var selection: SidebarSelection { get }
}

extension SplitViewDisplayable {
    func isDisplaying(in splitVC: UISplitViewController) -> Bool {
        splitVC.viewController(for: .supplementary) === self.supplimentary
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

        splitVC.setViewController(content.supplimentary, for: .supplementary)
        splitVC.setViewController(content.secondary, for: .secondary)

        content.displayed(in: splitVC)
    }
}
