/// Action commands in Reader cells
class ReaderPostCellActions: NSObject, ReaderPostCellDelegate {
    private let context: NSManagedObjectContext
    private weak var origin: UIViewController?
    private let topic: ReaderAbstractTopic?

    var imageRequestAuthToken: String? = nil
    var isLoggedIn: Bool = false
    private let visibleConfirmation: Bool

    init(context: NSManagedObjectContext, origin: UIViewController, topic: ReaderAbstractTopic? = nil, visibleConfirmation: Bool = true) {
        self.context = context
        self.origin = origin
        self.topic = topic
        self.visibleConfirmation = visibleConfirmation
        super.init()
    }

    func readerCell(_ cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost, let origin = origin else {
            return
        }
        ReaderHeaderAction().execute(post: post, origin: origin)
    }

    func readerCell(_ cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost, let origin = origin else {
            return
        }
        ReaderCommentAction().execute(post: post, origin: origin)
    }

    func readerCell(_ cell: ReaderPostCardCell, followActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleFollowingForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleSavedForLater(for: post)
    }

    func readerCell(_ cell: ReaderPostCardCell, shareActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        guard let post = provider as? ReaderPost else {
            return
        }
        sharePost(post, fromView: sender)
    }

    func readerCell(_ cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        visitSiteForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleLikeForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        guard let post = provider as? ReaderPost, let origin = origin else {
            return
        }

        ReaderMenuAction(logged: isLoggedIn).execute(post: post, context: context, readerTopic: topic, anchor: sender, vc: origin)
    }

    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        showAttributionForPost(post)
    }

    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String? {
        return imageRequestAuthToken
    }

    fileprivate func toggleFollowingForPost(_ post: ReaderPost) {
        let siteTitle = post.blogNameForDisplay()
        let siteID = post.siteID
        let toFollow = !post.isFollowing

        ReaderFollowAction().execute(with: post, context: context) { [weak self] in
            if toFollow {
                self?.origin?.dispatchSubscribingNotificationNotice(with: siteTitle, siteID: siteID)
            }
        }
    }

    func toggleSavedForLater(for post: ReaderPost) {
        let actionOrigin: ReaderSaveForLaterOrigin
        if origin is ReaderSavedPostsViewController {
            actionOrigin = .savedStream
        } else {
            actionOrigin = .otherStream
        }

        if !post.isSavedForLater {
            if let origin = origin as? UIViewController & UIViewControllerTransitioningDelegate {
                FancyAlertViewController.presentReaderSavedPostsAlertControllerIfNecessary(from: origin)
            }
        }

        ReaderSaveForLaterAction(visibleConfirmation: visibleConfirmation).execute(with: post, context: context, origin: actionOrigin)
    }

    fileprivate func visitSiteForPost(_ post: ReaderPost) {
        guard let origin = origin else {
            return
        }
        ReaderVisitSiteAction().execute(with: post, context: ContextManager.sharedInstance().mainContext, origin: origin)
    }

    fileprivate func showAttributionForPost(_ post: ReaderPost) {
        guard let origin = origin else {
            return
        }
        ReaderShowAttributionAction().execute(with: post, context: context, origin: origin)
    }


    fileprivate func toggleLikeForPost(_ post: ReaderPost) {
        ReaderLikeAction().execute(with: post, context: context)
    }

    fileprivate func sharePost(_ post: ReaderPost, fromView anchorView: UIView) {
        guard let origin = origin else {
            return
        }
        ReaderShareAction().execute(with: post, context: context, anchor: anchorView, vc: origin)
    }
}

enum ReaderActionsVisibility: Equatable {
    case hidden
    case visible(enabled: Bool)

    static func == (lhs: ReaderActionsVisibility, rhs: ReaderActionsVisibility) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden):
            return true
        case (.visible(let lenabled), .visible(let renabled)):
            return lenabled == renabled
        default:
            return false
        }
    }

    var isEnabled: Bool {
        switch self {
        case .hidden:
            return false
        case .visible(let enabled):
            return enabled
        }
    }
}
