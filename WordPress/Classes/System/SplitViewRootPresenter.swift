import UIKit
import Combine

/// The presenter that uses triple-column navigation for `.regular` size classes
/// and a tab-bar based navigation for `.compact` size class.
final class SplitViewRootPresenter: RootViewPresenter {
    private let sidebarViewModel = SidebarViewModel()
    private let splitVC = UISplitViewController(style: .tripleColumn)
    private var cancellables: [AnyCancellable] = []

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

        splitVC.preferredSplitBehavior = .tile

        let sidebarVC = SidebarViewController(viewModel: sidebarViewModel)
        splitVC.setViewController(sidebarVC, for: .primary)

        let tabBarVC = WPTabBarController(staticScreens: false)
        splitVC.setViewController(tabBarVC, for: .compact)
    }

    private func configure(for selection: SidebarSelection) {
        splitVC.preferredSupplementaryColumnWidth = selection == .reader ? 320 : UISplitViewController.automaticDimension

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
                // TODO: (wpsidebar) show empty state
            }
        case .notifications:
            // TODO: (wpsidebar) update tab bar item when new notifications arrive
            let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateInitialViewController()
            splitVC.setViewController(notificationsVC, for: .supplementary)
        case .reader:
            let readerVC = ReaderViewController()

            // TODO: (wpsidebar) add search
            let readerSidebarVS = ReaderSidebarViewController(viewModel: readerVC.readerTabViewModel)
            splitVC.setViewController(readerSidebarVS, for: .supplementary)
            splitVC.setViewController(readerVC, for: .secondary)
        case .domains:
            // TODO: (wisidebar) figure out what to do with selection
            let domainsVC = AllDomainsListViewController()
            let navigationVC = UINavigationController(rootViewController: domainsVC)
            splitVC.present(navigationVC, animated: true)
        case .help:
            let supportVC = SupportTableViewController()
            let navigationVC = UINavigationController(rootViewController: supportVC)
            splitVC.present(navigationVC, animated: true)
            break
        }
    }

    // MARK: – RootViewPresenter

    var rootViewController: UIViewController { splitVC }

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
        splitVC.present(meViewController, animated: true)
    }

    func popMeScreenToRoot() {
        fatalError()
    }
}

extension SplitViewRootPresenter: SiteMenuViewControllerDelegate {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        splitVC.setViewController(viewController, for: .secondary)
    }
}
