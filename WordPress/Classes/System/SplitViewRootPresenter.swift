import UIKit

final class SplitViewRootPresenter: RootViewPresenter {
    let rootViewController: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .red
        return vc
    }()

    init() {
        self.mySitesCoordinator = MySitesCoordinator(meScenePresenter: MeScenePresenter(), onBecomeActiveTab: {})
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
