/// Encapsulates a command to flag a site
final class ReaderBlockSiteAction {
    private let asBlocked: Bool

    init(asBlocked: Bool) {
        self.asBlocked = asBlocked
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        let service = ReaderSiteService(managedObjectContext: context)
        service.flagSite(withID: post.siteID,
                         asBlocked: asBlocked,
                         success: {
                            WPAnalytics.trackReader(.readerBlogBlocked, properties: ["blogId": post.siteID as Any])
                            completion?()
                         },
                         failure: failure)
    }
}
