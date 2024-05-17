final class CommentModerationViewModel: ObservableObject {
    private enum Constants {
        static let notificationDetailSource = ["source": "notification_details"]
    }

    @Published var state: CommentModerationState
    private let comment: Comment
    private let coordinator: CommentModerationCoordinator
    private let notification: Notification?
    private let stateChanged: ((Result<CommentModerationState, Error>) -> Void)?

    private var isNotificationComment: Bool {
        notification != nil
    }

    var userName: String {
        comment.author
    }

    var imageURL: URL? {
        URL(string: comment.authorAvatarURL)
    }

    private lazy var commentService: CommentService = {
        return .init(coreDataStack: ContextManager.shared)
    }()

    // Temporary init argument
    init(
        state: CommentModerationState,
        comment: Comment,
        coordinator: CommentModerationCoordinator,
        notification: Notification?,
        stateChanged: ((Result<CommentModerationState, Error>) -> Void)?
    ) {
        self.state = state
        self.comment = comment
        self.coordinator = coordinator
        self.notification = notification
        self.stateChanged = stateChanged
    }

    func didChangeState(to state: CommentModerationState) {
        switch state {
        case .pending:
            unapproveComment()
        case .approved(let liked):
            approveComment()
        case .trash:
            trashComment()
        case .spam:
            spamComment()
        }
    }

    func didTapReply() {
        // TODO
    }

    func didTapPrimaryCTA() {
        switch state {
        case .pending:
            approveComment()
        case .trash:
            trashComment()
        default:
            () // Do nothing
        }
    }

    func didTapMore() {
        coordinator.didTapMoreOptions()
    }

    func didTapLike() {
        switch state {
        case .approved(let liked):
            state = .approved(liked: !liked)
        default:
            break
        }
    }
}

private extension CommentModerationViewModel {
    func approveComment() {
        track(withEvent: .notificationsCommentApproved) { comment in
            CommentAnalytics.trackCommentApproved(comment: comment)
        }

        coordinator.didSelectOption()
        commentService.approve(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .approved(liked: false))
        }, failure: { [weak self] error in
            self?.handleStatusChangeFailure(error: error)
        })
    }

    func unapproveComment() {
        track(withEvent: .notificationsCommentUnapproved) { comment in
            CommentAnalytics.trackCommentUnApproved(comment: comment)
        }

        coordinator.didSelectOption()
        commentService.unapproveComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .pending)
        }, failure: { [weak self] error in
            self?.handleStatusChangeFailure(error: error)
        })
    }

    func spamComment() {
        track(withEvent: .notificationsCommentFlaggedAsSpam) { comment in
            CommentAnalytics.trackCommentSpammed(comment: comment)
        }
        coordinator.didSelectOption()
        commentService.spamComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .spam)
        }, failure: { [weak self] error in
            self?.handleStatusChangeFailure(error: error)
        })
    }

    func trashComment() {
        track(withEvent: .notificationsCommentTrashed) { comment in
            CommentAnalytics.trackCommentTrashed(comment: comment)
        }
        coordinator.didSelectOption()
        commentService.trashComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .trash)
        }, failure: { [weak self] error in
            self?.handleStatusChangeFailure(error: error)
        })
    }

    func track(withEvent event: WPAnalyticsStat, commentAnalyticsClosure: (Comment) -> Void) {
        if isNotificationComment {
            WPAppAnalytics.track(
                event,
                withProperties: Constants.notificationDetailSource,
                withBlogID: notification?.metaSiteID
            )
        } else {
            commentAnalyticsClosure(comment)
        }
    }

    func handleStatusChangeSuccess(state: CommentModerationState) {
        self.state = state
        stateChanged?(.success(state))
    }

    func handleStatusChangeFailure(error: Error?) {
        stateChanged?(.failure(error!)) // FIXME: Remove force unwrap
    }
}
