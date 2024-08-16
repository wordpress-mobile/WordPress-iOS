import UIKit

final class SplitViewRootPresenter: RootViewPresenter {
    private let splitVC = UISplitViewController(style: .tripleColumn)

    init() {
        // TODO: (wpsidebar) remove this?
        self.mySitesCoordinator = MySitesCoordinator(meScenePresenter: MeScenePresenter(), onBecomeActiveTab: {})

        let sidebarVC = SidebarViewController()

        // TODO: (wpsidebar) Configure on iPad
        // These three columns are displayed with `.regular` size class
        splitVC.setViewController(sidebarVC, for: .primary)

        // TODO: (wpsidebar) Display based on the selection from sidebar
        if let blog = Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext) {
            let siteMenuVC = SiteMenuViewController(blog: blog)
            siteMenuVC.delegate = self
            splitVC.setViewController(siteMenuVC, for: .supplementary)

            // TODO: (wpsidebar) Refactor this (initial .secondary vc managed based on the VC presentation)
            _ = siteMenuVC.view
        } else {
            splitVC.setViewController(UIViewController(), for: .supplementary)
            splitVC.setViewController(UIViewController(), for: .secondary)
        }

        // The `.compact` column is displayed with `.compact` size class, including iPhone
        let tabBarVC = WPTabBarController(staticScreens: false)
        splitVC.setViewController(tabBarVC, for: .compact)
    }

    // MARK: – RootViewPresenter

    var rootViewController: UIViewController { splitVC }

    // MARK: – RootViewPresenter (Unimplemented)

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
        fatalError()
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
