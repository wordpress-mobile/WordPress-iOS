/// Encapsulates a command to reblog a post
class ReaderReblogAction {

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
    func execute(readerPost: ReaderPost, origin: UIViewController) {
        presenter.presentReblog(blogService: blogService,
                                readerPost: readerPost,
                                origin: origin)
    }
}
