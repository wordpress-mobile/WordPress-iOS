/// Encapsulates a command to reblog a post
class ReaderReblogAction {
    // tells if the origin is the reader list or detail, for analytics purposes
    enum ReblogSource {
        case list
        case detail
    }

    private let blogService: BlogService
    private let presenter: ReaderReblogPresenter

    init(blogService: BlogService? = nil,
         presenter: ReaderReblogPresenter = ReaderReblogPresenter()) {
        self.presenter = presenter

        // fallback for self.blogService
        func makeBlogService() -> BlogService {
            let context = ContextManager.sharedInstance().mainContext
            return BlogService(managedObjectContext: context)
        }
        self.blogService = blogService ?? makeBlogService()
    }

    /// Executes the reblog action on the origin UIViewController
    func execute(readerPost: ReaderPost, origin: UIViewController, reblogSource: ReblogSource) {
        trackReblog(readerPost: readerPost, reblogSource: reblogSource)

        presenter.presentReblog(blogService: blogService,
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
