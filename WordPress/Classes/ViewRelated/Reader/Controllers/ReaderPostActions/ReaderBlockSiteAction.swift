import CoreData
import WordPressData
import WordPressShared

/// Encapsulates a command to flag a site
final class ReaderBlockSiteAction {
    private let asBlocked: Bool

    init(asBlocked: Bool) {
        self.asBlocked = asBlocked
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        guard let siteID = post.siteID else {
            DispatchQueue.main.async {
                failure?(nil)
            }
            return
        }

        let service = ReaderSiteService(coreDataStack: ContextManager.shared)
        service.flagSite(withID: siteID,
                         asBlocked: asBlocked,
                         success: {
                            WPAnalytics.trackReader(.readerBlogBlocked, properties: ["blogId": post.siteID as Any])
                            completion?()
                         },
                         failure: failure)
    }
}
