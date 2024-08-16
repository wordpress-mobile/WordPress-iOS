import UIKit

final class SplitViewRootPresenter: RootViewPresenter {
    let rootViewController: UIViewController

    private let meScenePresenter = MeScenePresenter()

    init() {
        // TODO: (wpsidebar) remove this?
        self.mySitesCoordinator = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})

        let splitVC = UISplitViewController(style: .tripleColumn)

        // TODO: (wpsidebar) Configure on iPad
        // These three columns are displayed with `.regular` size class
        splitVC.setViewController(SidebarViewController(), for: .primary)
        // TODO: (wpsidebar) show blog DetailsVC directly
        splitVC.setViewController(mySitesCoordinator.navigationController, for: .supplementary)
        // TODO: (wpsidebar) delegate selection from BlogDetailsViewController
        splitVC.setViewController(UIViewController(), for: .secondary)

        // The `.compact` column is displayed with `.compact` size class, including iPhone
        let tabBarVC = WPTabBarController(staticScreens: false)
        splitVC.setViewController(tabBarVC, for: .compact)

        self.rootViewController = splitVC
    }

    // MARK: – RootViewPresenter

    // MARK: – RootViewPresenter (Unimplemented)

    var currentViewController: UIViewController?

    func showBlogDetails(for blog: Blog) {
        fatalError()
    }

    func getMeScenePresenter() -> any ScenePresenter {
        fatalError()
    }

    func currentlySelectedScreen() -> String {
        fatalError()
    }

    // TODO: Can we eliminate it?
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
