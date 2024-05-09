
struct ReaderTagCellViewModel {

    private weak var parentViewController: UIViewController?
    private let post: ReaderPost
    private let isLoggedIn: Bool
    private var followCommentsService: FollowCommentsService?

    init(parent: UIViewController?, post: ReaderPost, isLoggedIn: Bool) {
        self.parentViewController = parent
        self.post = post
        self.isLoggedIn = isLoggedIn
    }

    func onSiteTitleTapped() {
        guard let parentViewController else {
            return
        }
        ReaderHeaderAction().execute(post: post, origin: parentViewController)
    }

    func onLikeButtonTapped() {
        ReaderLikeAction().execute(with: post)
    }

    mutating func onMenuButtonTapped(with anchor: UIView) {
        guard let parentViewController = parentViewController as? ReaderStreamViewController,
              let followCommentsService = FollowCommentsService(post: post) else {
            return
        }
        self.followCommentsService = followCommentsService

        ReaderMenuAction(logged: isLoggedIn).execute(
            post: post,
            context: parentViewController.viewContext,
            readerTopic: parentViewController.readerTopic,
            anchor: anchor,
            vc: parentViewController,
            source: .tagCard,
            followCommentsService: followCommentsService,
            showAdditionalItems: true
        )
        // TODO: Analytics
    }

}
