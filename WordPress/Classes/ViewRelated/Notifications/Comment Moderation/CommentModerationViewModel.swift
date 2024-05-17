final class CommentModerationViewModel: ObservableObject {
    private enum Constants {
        static let notificationDetailSource = ["source": "notification_details"]
    }

    @Published var state: CommentModerationState
    @Published var isLoading: Bool = false
    private let comment: Comment
    private let coordinator: CommentModerationCoordinator
    private let notification: Notification?
    private let stateChanged: ((Result<CommentModerationState, CommentModerationError>) -> Void)?

    private var isNotificationComment: Bool {
        notification != nil
    }

    private var siteID: NSNumber? {
        return comment.blog?.dotComID ?? notification?.metaSiteID
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

    init(
        comment: Comment,
        coordinator: CommentModerationCoordinator,
        notification: Notification?,
        stateChanged: ((Result<CommentModerationState, CommentModerationError>) -> Void)?
    ) {
        self.state = CommentModerationState(comment: comment)
        self.comment = comment
        self.coordinator = coordinator
        self.notification = notification
        self.stateChanged = stateChanged
    }

    func didChangeState(to state: CommentModerationState) {
        switch state {
        case .pending:
            unapproveComment()
        case .approved:
            approveComment()
        case .trash:
            trashComment()
        case .spam:
            spamComment()
        case .deleted:
            deleteComment()
        }
    }

    func didTapReply() {
        // TODO
    }

    func didTapPrimaryCTA() {
        switch state {
        case .pending:
            approveComment()
        case .trash, .spam:
            deleteComment()
        default:
            () // Do nothing
        }
    }

    func didTapMore() {
        coordinator.didTapMoreOptions()
    }

    func didTapLike() {
        let initialIsLiked = comment.isLiked

        guard let siteID = siteID else {
            self.state = .approved(liked: initialIsLiked)
            return
        }

        if initialIsLiked {
            track(withEvent: .notificationsCommentLiked) { comment in
                CommentAnalytics.trackCommentUnLiked(comment: comment)
            }
        } else {
            track(withEvent: .notificationsCommentLiked) { comment in
                CommentAnalytics.trackCommentLiked(comment: comment)
            }
        }

        self.state = .approved(liked: !initialIsLiked)
        commentService.toggleLikeStatus(for: comment, siteID: siteID, success: { [weak self] in
            guard let self, let notification = self.notification else {
                return
            }
            let mediator = NotificationSyncMediator()
            mediator?.invalidateCacheForNotification(notification.notificationId, completion: {
                mediator?.syncNote(with: notification.notificationId)
            })
        }, failure: { _ in
            self.state = .approved(liked: initialIsLiked)
        })
    }
}

private extension CommentModerationViewModel {
    func approveComment() {
        track(withEvent: .notificationsCommentApproved) { comment in
            CommentAnalytics.trackCommentApproved(comment: comment)
        }

        isLoading = true
        coordinator.didSelectOption()
        commentService.approve(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .approved(liked: false))
        }, failure: { [weak self] _ in
            self?.handleStatusChangeFailure(error: .approved)
        })
    }

    func unapproveComment() {
        track(withEvent: .notificationsCommentUnapproved) { comment in
            CommentAnalytics.trackCommentUnApproved(comment: comment)
        }

        isLoading = true
        coordinator.didSelectOption()
        commentService.unapproveComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .pending)
        }, failure: { [weak self] _ in
            self?.handleStatusChangeFailure(error: .pending)
        })
    }

    func spamComment() {
        track(withEvent: .notificationsCommentFlaggedAsSpam) { comment in
            CommentAnalytics.trackCommentSpammed(comment: comment)
        }

        isLoading = true
        coordinator.didSelectOption()
        commentService.spamComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .spam)
        }, failure: { [weak self] _ in
            self?.handleStatusChangeFailure(error: .spam)
        })
    }

    func trashComment() {
        track(withEvent: .notificationsCommentTrashed) { comment in
            CommentAnalytics.trackCommentTrashed(comment: comment)
        }
        isLoading = true
        coordinator.didSelectOption()
        commentService.trashComment(comment, success: { [weak self] in
            self?.handleStatusChangeSuccess(state: .trash)
        }, failure: { [weak self] _ in
            self?.handleStatusChangeFailure(error: .trash)
        })
    }

    func deleteComment(completion: ((Bool) -> Void)? = nil) {
        CommentAnalytics.trackCommentTrashed(comment: comment)

        isLoading = true
        commentService.delete(comment, success: { [weak self] in
            guard let self else {
                return
            }
            self.handleStatusChangeSuccess(state: .deleted)
            self.coordinator.didDeleteComment()
            NotificationCenter.default.post(
                name: .NotificationCommentDeletedNotification,
                object: nil,
                userInfo: [userInfoCommentIdKey: self.comment.commentID]
            )
        }, failure: { [weak self] _ in
            self?.handleStatusChangeFailure(error: .deleted)
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
        isLoading = false
        stateChanged?(.success(state))
    }

    func handleStatusChangeFailure(error: CommentModerationError) {
        isLoading = false
        stateChanged?(.failure(error))
    }
}

// MARK: - CommentModerationError

extension CommentModerationViewModel {
    enum CommentModerationError: Error {
        case pending
        case approved
        case spam
        case trash
        case deleted

        var failureMessage: String {
            switch self {
            case .approved:
                return NSLocalizedString(
                    "Error approving comment.",
                    comment: "Message displayed when approving a comment fails."
                )
            case .pending:
                return NSLocalizedString(
                    "Error setting comment to pending.",
                    comment: "Message displayed when pending a comment fails."
                )
            case .spam:
                return NSLocalizedString(
                    "Error marking comment as spam.",
                    comment: "Message displayed when spamming a comment fails."
                )
            case .trash:
                return NSLocalizedString(
                    "Error moving comment to trash.",
                    comment: "Message displayed when trashing a comment fails."
                )
            case .deleted:
                return NSLocalizedString(
                    "Error deleting comment.",
                    comment: "Message displayed when deleting a comment fails."
                )
            }
        }
    }
}
