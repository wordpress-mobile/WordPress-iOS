final class ReaderMenuAction {
    private let isLoggedIn: Bool

    init(logged: Bool) {
        isLoggedIn = logged
    }
    func execute(post: ReaderPost, context: NSManagedObjectContext, readerTopic: ReaderAbstractTopic?, anchor: UIView, vc: UIViewController) {
        guard post.isFollowing else {
            showMenuForPost(post, context: context, readerTopic: readerTopic, fromView: anchor, vc: vc)
            return
        }

        let service: ReaderTopicService = ReaderTopicService(managedObjectContext: context)
        let siteTopic: ReaderSiteTopic? = service.findSiteTopic(withSiteID: post.siteID)

        showMenuForPost(post, context: context, topic: siteTopic, readerTopic: readerTopic, fromView: anchor, vc: vc)
    }

    fileprivate func showMenuForPost(_ post: ReaderPost, context: NSManagedObjectContext, topic: ReaderSiteTopic? = nil, readerTopic: ReaderAbstractTopic?, fromView anchorView: UIView, vc: UIViewController) {
        ReaderShowMenuAction(loggedIn: isLoggedIn).execute(with: post, context: context, topic: topic, readerTopic: readerTopic, anchor: anchorView, vc: vc)
    }
}
