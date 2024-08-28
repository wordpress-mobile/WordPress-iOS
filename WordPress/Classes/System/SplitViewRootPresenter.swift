import UIKit
import Combine

/// The presenter that uses triple-column navigation for `.regular` size classes
/// and a tab-bar based navigation for `.compact` size class.
final class SplitViewRootPresenter: RootViewPresenter {
    private let sidebarViewModel = SidebarViewModel()
    private let splitVC = UISplitViewController(style: .tripleColumn)
    private var cancellables: [AnyCancellable] = []

    init() {
        // TODO: (wpsidebar) refactor
        self.mySitesCoordinator = MySitesCoordinator(meScenePresenter: MeScenePresenter(), onBecomeActiveTab: {})

        let sidebarVC = SidebarViewController(viewModel: sidebarViewModel)
        let navigationVC = makeRootNavigationController(with: sidebarVC)
        splitVC.setViewController(navigationVC, for: .primary)

        let tabBarVC = WPTabBarController(staticScreens: false)
        splitVC.setViewController(tabBarVC, for: .compact)

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
    }

    private func configure(for selection: SidebarSelection) {
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
            // TODO: (wpsidebar) update tab bar item when new notifications arrive
            let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateInitialViewController() as! NotificationsViewController
            notificationsVC.isSidebarModeEnabled = true
            let navigationVC = UINavigationController(rootViewController: notificationsVC)
            splitVC.setViewController(navigationVC, for: .supplementary)
        case .reader:
            let readerVC = ReaderViewController()
            let readerSidebarVS = ReaderSidebarViewController(viewModel: readerVC.readerTabViewModel)
            splitVC.setViewController(makeRootNavigationController(with: readerSidebarVS), for: .supplementary)
            splitVC.setViewController(UINavigationController(rootViewController: readerVC), for: .secondary)
        }
    }

    private func showDetails(for site: Blog) {
        RecentSitesService().touch(blog: site)

        let siteMenuVC = SiteMenuViewController(blog: site)
        siteMenuVC.delegate = self
        let navigationVC = UINavigationController(rootViewController: siteMenuVC)
        splitVC.setViewController(navigationVC, for: .supplementary)

        // Reset navigation stack
        splitVC.setViewController(UINavigationController(), for: .secondary)

        // TODO: (wpsidebar) Refactor this (initial .secondary vc managed based on the VC presentation)
        _ = siteMenuVC.view
    }

    private func makeRootNavigationController(with viewController: UIViewController) -> UINavigationController {
        let navigationVC = UINavigationController(rootViewController: viewController)
        viewController.navigationItem.largeTitleDisplayMode = .automatic
        navigationVC.navigationBar.prefersLargeTitles = true
        return navigationVC
    }

    private func navigate(to step: SidebarNavigationStep) {
        switch step {
        case .allSites:
            showSitePicker()
        case .addSite(let selection):
            showAddSiteScreen(selection: selection)
        case .domains:
#if JETPACK
            let domainsVC = AllDomainsListViewController()
            let navigationVC = UINavigationController(rootViewController: domainsVC)
            navigationVC.modalPresentationStyle = .formSheet
            splitVC.present(navigationVC, animated: true)
#else
            wpAssertionFailure("domains are not supported in wpios")
#endif
        case .help:
            let supportVC = SupportTableViewController()
            let navigationVC = UINavigationController(rootViewController: supportVC)
            navigationVC.modalPresentationStyle = .formSheet
            splitVC.present(navigationVC, animated: true)
        case .profile:
            let meVC = MeSplitViewController()
            splitVC.present(meVC, animated: true)
        }
    }

    private func showSitePicker() {
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
        navigationVC.modalPresentationStyle = .formSheet
        self.splitVC.present(navigationVC, animated: true)
        WPAnalytics.track(.sidebarAllSitesTapped)
    }

    private func showAddSiteScreen(selection: AddSiteMenuViewModel.Selection) {
        AddSiteController(viewController: splitVC.presentedViewController ?? splitVC, source: "sidebar")
            .showSiteCreationScreen(selection: selection)
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
        mySitesCoordinator.currentBlog
    }

    func willDisplayPostSignupFlow() {
        fatalError()
    }

    var readerTabViewController: ReaderTabViewController?

    var readerCoordinator: ReaderCoordinator?

    var readerNavigationController: UINavigationController?

    func showReaderTab() {
        fatalError()
    }

    func showReaderTab(forPost: NSNumber, onBlog: NSNumber) {
        fatalError()
    }

    func switchToDiscover() {
        fatalError()
    }

    func switchToSavedPosts() {
        fatalError()
    }

    func resetReaderDiscoverNudgeFlow() {
        fatalError()
    }

    func resetReaderTab() {
        fatalError()
    }

    func navigateToReaderSearch() {
        fatalError()
    }

    func navigateToReaderSearch(withSearchText: String) {
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
        fatalError()
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

    var notificationsViewController: NotificationsViewController?

    func showNotificationsTab() {
        fatalError()
    }

    func showNotificationsTabForNote(withID notificationID: String) {
        fatalError()
    }

    func switchNotificationsTabToNotificationSettings() {
        fatalError()
    }

    func popNotificationsTabToRoot() {
        fatalError()
    }

    var meViewController: MeViewController?

    func showMeScreen() {
        navigate(to: .profile)
    }

    func popMeScreenToRoot() {
        fatalError()
    }
}

extension SplitViewRootPresenter: SiteMenuViewControllerDelegate {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        if viewController is UINavigationController ||
            viewController is UISplitViewController {
            splitVC.setViewController(viewController, for: .secondary)
        } else {
            // Reset previous navigation or split stack
            let navigationVC = UINavigationController(rootViewController: viewController)
            splitVC.setViewController(navigationVC, for: .secondary)
        }
    }
}
