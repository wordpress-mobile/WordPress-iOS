final class ReaderMenuAction {
    private let isLoggedIn: Bool

    init(logged: Bool) {
        isLoggedIn = logged
    }

    func execute(post: ReaderPost,
                 context: NSManagedObjectContext,
                 readerTopic: ReaderAbstractTopic? = nil,
                 anchor: UIView,
                 vc: UIViewController,
                 source: ReaderPostMenuSource) {
        let service: ReaderTopicService = ReaderTopicService(managedObjectContext: context)
        let siteTopic: ReaderSiteTopic? = post.isFollowing ? service.findSiteTopic(withSiteID: post.siteID) : nil

        ReaderShowMenuAction(loggedIn: isLoggedIn).execute(with: post,
                                                           context: context,
                                                           siteTopic: siteTopic,
                                                           readerTopic: readerTopic,
                                                           anchor: anchor,
                                                           vc: vc,
                                                           source: source)
    }
}
