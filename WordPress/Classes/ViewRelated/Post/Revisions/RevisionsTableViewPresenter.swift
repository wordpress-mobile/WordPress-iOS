protocol RevisionsView: class {
    func startLoading()
    func stopLoadigng(success: Bool, error: Error?)
}


final class RevisionsTableViewPresenter {
    let title = NSLocalizedString("History", comment: "Title of the post history screen")
    let context = ContextManager.sharedInstance().mainContext

    private var isLoading = false
    private weak var revisionsView: RevisionsView?
    private let post: AbstractPost
    private lazy var postService: PostService = {
        return PostService(managedObjectContext: context)
    }()

    init(post: AbstractPost, attach revisionsView: RevisionsView?) {
        self.post = post
        self.revisionsView = revisionsView
    }

    func getRevisions() {
        if isLoading {
            return
        }

        isLoading = true

        postService.getPostRevisions(for: post, success: { [weak self] _ in
            DispatchQueue.main.async {
                self?.revisionsView?.stopLoadigng(success: true, error: nil)
            }
        }) { [weak self] error in
            self?.revisionsView?.stopLoadigng(success: false, error: error)
        }
    }
}
