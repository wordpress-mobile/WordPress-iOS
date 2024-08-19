import UIKit
import Combine

/// The presenter that uses triple-column navigation for `.regular` size classes
/// and a tab-bar based navigation for `.compact` size class.
final class SplitViewRootPresenter: RootViewPresenter {
    private let sidebarViewModel = SidebarViewModel()
    private let rootVC = DynamicRootViewController()
    private var splitVC = UISplitViewController(style: .tripleColumn)
    private var cancellables: [AnyCancellable] = []

    private var splitViewStyle: UISplitViewController.Style = .tripleColumn {
        didSet {
            guard oldValue != splitViewStyle else { return }
            splitVC = UISplitViewController(style: splitViewStyle)
            configure(splitVC)
        }
    }

    init() {
        // TODO: (wpsidebar) remove this?
        self.mySitesCoordinator = MySitesCoordinator(meScenePresenter: MeScenePresenter(), onBecomeActiveTab: {})

        let blog = Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext)
        if let blog {
            sidebarViewModel.selection = .blog(TaggedManagedObjectID(blog))
        } else {
            sidebarViewModel.selection = .empty
        }
        // TODO: (wpsidebar) add to recent sites, etc – do everything MySiteVC does
        sidebarViewModel.$selection.compactMap { $0 }.sink { [weak self] in
            self?.configure(for: $0)
        }.store(in: &cancellables)

        sidebarViewModel.showProfileDetails = { [weak self] in
            self?.showMeScreen()
        }

        configure(splitVC)
    }

    /// There is no convenience API for dynamically switching from `.tripleColumn`
    /// to `.doubleColumn` split view controller style. So instead the app
    /// recreates the entire UISplitViewController but keep the sidebar.
    ///
    /// - seealso: https://stackoverflow.com/questions/68336349/swift-uisplitviewcontroller-how-to-go-from-triple-to-double-columns
    private func configure(_ splitViewController: UISplitViewController) {
        let sidebarVC = SidebarViewController(viewModel: sidebarViewModel)
        splitVC.setViewController(sidebarVC, for: .primary)

        // The `.compact` column is displayed with `.compact` size class, including iPhone
        let tabBarVC = WPTabBarController(staticScreens: false)
        splitVC.setViewController(tabBarVC, for: .compact)

        rootVC.contentViewController = splitVC
    }

    private func configure(for selection: SidebarSelection) {
        splitViewStyle = getSplitViewStyle(for: selection)

        switch selection {
        case .empty:
            // TODO: (sidebar) add support for the "no sites" scenario
            break
        case .blog(let objectID):
            do {
                let blog = try ContextManager.shared.mainContext.existingObject(with: objectID)

                let siteMenuVC = SiteMenuViewController(blog: blog)
                siteMenuVC.delegate = self
                splitVC.setViewController(siteMenuVC, for: .supplementary)

                // TODO: (wpsidebar) Refactor this (initial .secondary vc managed based on the VC presentation)
                _ = siteMenuVC.view

            } catch {
                // TODO: (wpsidebar) show empty state?
            }
        case .notifications:
            // TODO: (wpsidebar) update tab bar item accordingly
            let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateInitialViewController()
            splitVC.setViewController(notificationsVC, for: .supplementary)
        case .reader:
            let readerVC = ReaderViewController()
            splitVC.setViewController(readerVC, for: .secondary)
        case .domains:
            // TODO: (wisidebar) figure out what to do with selection
            let domainsVC = AllDomainsListViewController()
            let navigationVC = UINavigationController(rootViewController: domainsVC)
            rootVC.present(navigationVC, animated: true)
        case .help:
            let supportVC = SupportTableViewController()
            let navigationVC = UINavigationController(rootViewController: supportVC)
            rootVC.present(navigationVC, animated: true)
            break
        }
    }

    private func getSplitViewStyle(for selection: SidebarSelection) -> UISplitViewController.Style {
        switch selection {
        case .empty, .reader:
            return .doubleColumn
        default:
            return .tripleColumn
        }
    }

    // MARK: – RootViewPresenter

    var rootViewController: UIViewController { rootVC }

    var currentViewController: UIViewController?

    func showBlogDetails(for blog: Blog) {
        fatalError()
    }

    func getMeScenePresenter() -> any ScenePresenter {
        fatalError()
    }

    func currentlySelectedScreen() -> String {
        ""
    }

    // TODO: (wpsidebar) Can we eliminate it?
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
        let meViewController = MeSplitViewController()
        rootVC.present(meViewController, animated: true)
    }

    func popMeScreenToRoot() {
        fatalError()
    }
}

private final class DynamicRootViewController: UIViewController {
    var contentViewController: UIViewController? {
        didSet {
            if let viewController = oldValue {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }
            if let viewController = contentViewController {
                addChild(viewController)
                view.addSubview(viewController.view)
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                view.pinSubviewToAllEdges(viewController.view)
                viewController.didMove(toParent: self)
            }
        }
    }
}

extension SplitViewRootPresenter: SiteMenuViewControllerDelegate {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        splitVC.setViewController(viewController, for: .secondary)
    }
}
