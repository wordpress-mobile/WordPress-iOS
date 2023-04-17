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
                 source: ReaderPostMenuSource,
                 followCommentsService: FollowCommentsService
    ) {
        self.execute(post: post, context: context, anchor: .view(anchor), vc: vc, source: source, followCommentsService: followCommentsService)
    }

    func execute(post: ReaderPost,
                 context: NSManagedObjectContext,
                 readerTopic: ReaderAbstractTopic? = nil,
                 anchor: ReaderShowMenuAction.PopoverAnchor,
                 vc: UIViewController,
                 source: ReaderPostMenuSource,
                 followCommentsService: FollowCommentsService
    ) {
        let siteTopic: ReaderSiteTopic? = post.isFollowing ? (try? ReaderSiteTopic.lookup(withSiteID: post.siteID, in: context)) : nil

        ReaderShowMenuAction(loggedIn: isLoggedIn).execute(
            with: post,
            context: context,
            siteTopic: siteTopic,
            readerTopic: readerTopic,
            anchor: anchor,
            vc: vc,
            source: source,
            followCommentsService: followCommentsService
        )
    }
}
