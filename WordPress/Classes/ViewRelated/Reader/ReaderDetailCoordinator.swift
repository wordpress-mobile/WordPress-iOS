import Foundation

class ReaderDetailCoordinator {

    /// Reader Post Service
    private let service: ReaderPostService

    /// Reader View
    private weak var view: ReaderDetailView?

    /// A post to be displayed
    var post: ReaderPost?

    /// A post ID to fetch
    var postID: NSNumber?

    /// A site ID to be used to fetch a post
    var siteID: NSNumber?

    /// If the site is an external feed (not hosted at WPcom and not using Jetpack)
    var isFeed: Bool?

    /// Initialize the Reader Detail Coordinator
    ///
    /// - Parameter service: a Reader Post Service
    init(service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         view: ReaderDetailView) {
        self.service = service
        self.view = view
    }

    func start() {
        if let post = post {
            view?.render(post)
        } else if let siteID = siteID, let postID = postID, let isFeed = isFeed {
            fetch(postID: postID, siteID: siteID, isFeed: isFeed)
        }
    }

    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    private func fetch(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
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
