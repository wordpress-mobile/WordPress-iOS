protocol RevisionsView: AnyObject {
    func stopLoading(success: Bool, error: Error?)
}


final class ShowRevisionsListManger {
    let context = ContextManager.sharedInstance().mainContext

    private var isLoading = false
    private weak var revisionsView: RevisionsView?
    private let post: AbstractPost?
    private lazy var postService: PostService = {
        return PostService(managedObjectContext: context)
    }()

    init(post: AbstractPost?, attach revisionsView: RevisionsView?) {
        self.post = post
        self.revisionsView = revisionsView
    }

    func getRevisions() {
        guard let post = post else {
            return
        }

        if isLoading {
            return
        }

        isLoading = true

        postService.getPostRevisions(for: post, success: { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.revisionsView?.stopLoading(success: true, error: nil)
            }
        }) { [weak self] error in
            self?.isLoading = false
            self?.revisionsView?.stopLoading(success: false, error: error)
        }
    }
}
