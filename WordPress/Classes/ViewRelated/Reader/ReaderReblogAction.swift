/// Encapsulates a command to reblog a post
class ReaderReblogAction {
    // tells if the origin is the reader list or detail, for analytics purposes
    enum OriginType {
        case list, detail
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
    func execute(readerPost: ReaderPost, origin: UIViewController, originType: OriginType) {
        trackReblog(readerPost: readerPost, originType: originType)

        presenter.presentReblog(blogService: blogService,
                                readerPost: readerPost,
                                origin: origin)
    }
}

// MARK: - Analytics
extension ReaderReblogAction {
    fileprivate func trackReblog(readerPost: ReaderPost, originType: OriginType) {


        let properties = [WPAppAnalyticsKeyBlogID: readerPost.siteID,
                          WPAppAnalyticsKeyPostID: readerPost.postID]

        let stat: WPAnalyticsStat = originType == .detail ?
            .readerArticleDetailReblogged :
            .readerArticleReblogged

        WPAnalytics.track(stat, withProperties: properties as [AnyHashable: Any])
    }
}
