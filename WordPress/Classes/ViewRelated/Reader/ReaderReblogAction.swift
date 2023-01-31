/// Encapsulates a command to reblog a post
class ReaderReblogAction {
    // tells if the origin is the reader list or detail, for analytics purposes
    enum ReblogSource {
        case list
        case detail
    }

    private let coreDataStack: CoreDataStack
    private let presenter: ReaderReblogPresenter

    init(coreDataStack: CoreDataStack = ContextManager.shared,
         presenter: ReaderReblogPresenter = ReaderReblogPresenter()) {
        self.coreDataStack = coreDataStack
        self.presenter = presenter
    }

    /// Executes the reblog action on the origin UIViewController
    func execute(readerPost: ReaderPost, origin: UIViewController, reblogSource: ReblogSource) {
        trackReblog(readerPost: readerPost, reblogSource: reblogSource)

        presenter.presentReblog(coreDataStack: coreDataStack,
                                readerPost: readerPost,
                                origin: origin)
    }
}

// MARK: - Analytics
extension ReaderReblogAction {
    private func trackReblog(readerPost: ReaderPost, reblogSource: ReblogSource) {

        let properties = [WPAppAnalyticsKeyBlogID: readerPost.siteID,
                          WPAppAnalyticsKeyPostID: readerPost.postID]

        let stat: WPAnalyticsStat = reblogSource == .detail ?
            .readerArticleDetailReblogged :
            .readerArticleReblogged

        WPAnalytics.track(stat, withProperties: properties as [AnyHashable: Any])
    }
}
