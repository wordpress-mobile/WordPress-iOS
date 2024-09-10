import Foundation

protocol RootViewPresenter: AnyObject {

    // MARK: General

    var rootViewController: UIViewController { get }
    var currentViewController: UIViewController? { get }
    func showBlogDetails(for blog: Blog)
    func getMeScenePresenter() -> ScenePresenter
    func currentlySelectedScreen() -> String
    func currentlyVisibleBlog() -> Blog?
    func willDisplayPostSignupFlow()

    // MARK: Reader

    var readerTabViewController: ReaderTabViewController? { get }
    var readerCoordinator: ReaderCoordinator? { get }
    var readerNavigationController: UINavigationController? { get }
    func showReaderTab()
    func showReaderTab(forPost: NSNumber, onBlog: NSNumber)
    func switchToDiscover()
    func navigateToReaderSearch()
    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool)
    func switchToMyLikes()
    func switchToFollowedSites()
    func navigateToReaderSite(_ topic: ReaderSiteTopic)
    func navigateToReaderTag(_ tagSlug: String)
    func navigateToReader(_ pushControlller: UIViewController?)

    // MARK: My Site

    var mySitesCoordinator: MySitesCoordinator { get }
    func showMySitesTab()
    func showPages(for blog: Blog)
    func showPosts(for blog: Blog)
    func showMedia(for blog: Blog)

    // MARK: Notifications

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?)

    // MARK: Me

    func showMeScreen(completion: ((MeViewController) -> Void)?)
}

extension RootViewPresenter {

    func showNotificationsTab() {
        showNotificationsTab(completion: nil)
    }

    func showNotificationsTabForNote(withID notificationID: String) {
        showNotificationsTab {
            $0.showDetailsForNotificationWithID(notificationID)
        }
    }

    func popNotificationsTabToRoot() {
        showNotificationsTab {
            $0.navigationController?.popToRootViewController(animated: false)
        }
    }

    func switchNotificationsTabToNotificationSettings() {
        showNotificationsTab {
            $0.navigationController?.popToRootViewController(animated: false)
            $0.showNotificationSettings()
        }
    }
}
