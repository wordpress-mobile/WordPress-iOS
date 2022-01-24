/// Action commands in Reader cells
class ReaderPostCellActions: NSObject, ReaderPostCellDelegate {
    private let context: NSManagedObjectContext
    private weak var origin: UIViewController?
    private let topic: ReaderAbstractTopic?

    var imageRequestAuthToken: String? = nil
    var isLoggedIn: Bool = false
    var visibleConfirmation: Bool {
        didSet {
            saveForLaterAction?.visibleConfirmation = visibleConfirmation
        }
    }

    private weak var saveForLaterAction: ReaderSaveForLaterAction?

    /// Saved posts that have been removed but not yet discarded
    var removedPosts = ReaderSaveForLaterRemovedPosts()
    weak var savedPostsDelegate: ReaderSavedPostCellActionsDelegate?

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

        if let controller = origin as? ReaderStreamViewController,
           let indexPath = controller.tableView.indexPath(for: cell),
           let topic = controller.readerTopic,
           ReaderHelpers.topicIsDiscover(topic),
           controller.shouldShowCommentSpotlight {
            controller.reloadReaderDiscoverNudgeFlow(at: indexPath)
        }

        ReaderCommentAction().execute(post: post, origin: origin, source: .postCard)
    }

    func readerCell(_ cell: ReaderPostCardCell, followActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleFollowingForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let origin = origin as? ReaderStreamViewController, origin.contentType == .saved {
            if let post = provider as? ReaderPost {
                removedPosts.add(post)
            }
            savedPostsDelegate?.willRemove(cell)
        } else {
            guard let post = provider as? ReaderPost else {
                return
            }
            toggleSavedForLater(for: post)
        }
    }

    func readerCell(_ cell: ReaderPostCardCell, shareActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        guard let post = provider as? ReaderPost else {
            return
        }
        sharePost(post, fromView: sender)
    }

    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }

        ReaderLikeAction().execute(with: post, context: context, completion: {
            cell.refreshLikeButton()
        })
    }

    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        guard let post = provider as? ReaderPost, let origin = origin else {
            return
        }

        ReaderMenuAction(logged: isLoggedIn).execute(post: post, context: context, readerTopic: topic, anchor: sender, vc: origin, source: ReaderPostMenuSource.card)
        WPAnalytics.trackReader(.postCardMoreTapped)
    }

    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        showAttributionForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, reblogActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost, let origin = origin else {
            return
        }
        ReaderReblogAction().execute(readerPost: post, origin: origin, reblogSource: .list)
    }

    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String? {
        return imageRequestAuthToken
    }

    private func toggleFollowingForPost(_ post: ReaderPost) {
        ReaderFollowAction().execute(with: post,
                                     context: context,
                                     completion: { follow in
                                        ReaderHelpers.dispatchToggleFollowSiteMessage(post: post, follow: follow, success: true)
                                     }, failure: { follow, _ in
                                        ReaderHelpers.dispatchToggleFollowSiteMessage(post: post, follow: follow, success: false)
                                     })
    }

    func toggleSavedForLater(for post: ReaderPost) {
        let actionOrigin: ReaderSaveForLaterOrigin

        if let origin = origin as? ReaderStreamViewController, origin.contentType == .saved {
            actionOrigin = .savedStream
        } else {
            actionOrigin = .otherStream
        }

        if !post.isSavedForLater {
            if let origin = origin as? ReaderStreamViewController, origin.contentType != .saved {
                FancyAlertViewController.presentReaderSavedPostsAlertControllerIfNecessary(from: origin)
            }
        }

        let saveAction = ReaderSaveForLaterAction(visibleConfirmation: visibleConfirmation)

        saveAction.execute(with: post, context: context, origin: actionOrigin, viewController: origin)
        saveForLaterAction = saveAction
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


// MARK: - Saved Posts
extension ReaderPostCellActions {

    func postIsRemoved(_ post: ReaderPost) -> Bool {
        return removedPosts.contains(post)
    }

    func restoreUnsavedPost(_ post: ReaderPost) {
        removedPosts.remove(post)
    }

    func clearRemovedPosts() {
        removedPosts.all().forEach({ toggleSavedForLater(for: $0) })
        removedPosts = ReaderSaveForLaterRemovedPosts()
    }
}
