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

        commentService.approve(comment, success: { [weak self] in
            self?.state = .approved(liked: false)
            self?.stateChanged?(.success(.approved(liked: false)))
        }, failure: { [weak self] error in
            self?.stateChanged?(.failure(error!)) // FIXME: Remove force unwrap
        })
    }

    func unapproveComment() {
        track(withEvent: .notificationsCommentUnapproved) { comment in
            CommentAnalytics.trackCommentUnApproved(comment: comment)
        }

        commentService.unapproveComment(comment, success: { [weak self] in
            self?.state = .pending
            self?.stateChanged?(.success(.pending))
        }, failure: { [weak self] error in
            self?.stateChanged?(.failure(error!)) // FIXME: Remove force unwrap
        })
    }

    func spamComment() {
        track(withEvent: .notificationsCommentFlaggedAsSpam) { comment in
            CommentAnalytics.trackCommentSpammed(comment: comment)
        }
        commentService.spamComment(comment, success: { [weak self] in
            self?.state = .spam
            self?.stateChanged?(.success(.spam))
        }, failure: { [weak self] error in
            self?.stateChanged?(.failure(error!)) // FIXME: Remove force unwrap
        })
    }

    func trashComment() {
        track(withEvent: .notificationsCommentTrashed) { comment in
            CommentAnalytics.trackCommentTrashed(comment: comment)
        }
        commentService.trashComment(comment, success: { [weak self] in
            self?.state = .trash
            self?.stateChanged?(.success(.trash))
        }, failure: { [weak self] error in
            self?.stateChanged?(.failure(error!)) // FIXME: Remove force unwrap
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
}
