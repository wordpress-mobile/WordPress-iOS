import Foundation

protocol RootViewPresenter {

    // MARK: General

    var rootViewController: UIViewController { get }
    func showBlogDetails(for blog: Blog)

    // MARK: Reader

    func showReaderTab()
    func switchToDiscover()
    func navigateToReaderSearch()
    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool)
    func switchToMyLikes()
    func switchToFollowedSites()
    func navigateToReaderSite(_ topic: ReaderSiteTopic)
    func navigateToReaderTag( _ topic: ReaderTagTopic)
    func navigateToReader(_ pushControlller: UIViewController?)
}
