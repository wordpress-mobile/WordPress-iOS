import Foundation

class ReaderDetailCoordinator {

    /// Reader Post Service
    private let service: ReaderPostService

    private weak var view: ReaderDetailView?

    /// Initialize the Reader Detail Coordinator
    ///
    /// - Parameter service: a Reader Post Service
    init(service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         view: ReaderDetailView) {
        self.service = service
        self.view = view
    }

    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    func fetch(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        service.fetchPost(postID.uintValue,
                          forSite: siteID.uintValue,
                          isFeed: isFeed,
                          success: { [weak self] post in
                            guard let post = post else {
                                return
                            }

                            self?.view?.render(post)
        }, failure: { [weak self] error in
            self?.view?.showError()
        })
    }

}
