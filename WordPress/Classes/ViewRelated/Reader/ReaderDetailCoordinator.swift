import Foundation

class ReaderDetailCoordinator {

    private let service: ReaderPostService

    init(service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext)) {
        self.service = service
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
                          success: { post in
                            // Post returned
        }, failure: { error in
            // Error
        })
    }

}
