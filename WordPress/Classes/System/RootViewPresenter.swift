import Foundation

protocol RootViewPresenter {

    // MARK: General

    var rootViewController: UIViewController { get }
    func showBlogDetails(for blog: Blog)
    func getMeScenePresenter() -> ScenePresenter
    func currentlySelectedScreen() -> String!

    // MARK: Reader

    var readerTabViewController: ReaderTabViewController? { get }
    func showReaderTab()
    func showReaderTab(forPost: NSNumber!, onBlog: NSNumber!)
    func switchToDiscover()
    func switchToSavedPosts()
    func resetReaderDiscoverNudgeFlow()
    func resetReaderTab()
    func navigateToReaderSearch()
    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool)
    func switchToMyLikes()
    func switchToFollowedSites()
    func navigateToReaderSite(_ topic: ReaderSiteTopic)
    func navigateToReaderTag( _ topic: ReaderTagTopic)
    func navigateToReader(_ pushControlller: UIViewController?)

    // MARK: My Site

    func showMySitesTab()
    func showPages(for blog: Blog)
    func showPosts(for blog: Blog)
    func showMedia(for blog: Blog)

    // MARK: Notifications

    func showNotificationsTab()
    func showNotificationsTabForNote(withID notificationID: String!)
    func switchNotificationsTabToNotificationSettings()

}
