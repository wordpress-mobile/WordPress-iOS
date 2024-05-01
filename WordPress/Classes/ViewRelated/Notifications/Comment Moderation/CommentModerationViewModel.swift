final class CommentModerationViewModel: ObservableObject {
    @Published var state: CommentModerationState
    private let comment: Comment

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
    init(state: CommentModerationState, comment: Comment) {
        self.state = state
        self.comment = comment
    }

    func didChangeState(to state: CommentModerationState) {
        // TODO
    }

    func didTapReply() {
        // TODO
    }

    func didTapPrimaryCTA() {
        switch state {
        case .pending:
            state = .approved
//            isNotificationComment ? WPAppAnalytics.track(.notificationsCommentApproved,
//                                                         withProperties: Constants.notificationDetailSource,
//                                                         withBlogID: notification?.metaSiteID) :
//                                    CommentAnalytics.trackCommentApproved(comment: comment)
//
            commentService.approve(comment, success: { [weak self] in
//                self?.showActionableNotice(title: ModerationMessages.approveSuccess)
//                self?.refreshData()
            }, failure: { [weak self] error in
//                self?.displayNotice(title: ModerationMessages.approveFail)
//                self?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
            })
        case .trash:
            () // Delete comment
        case .approved, .liked:
            break
        }
    }

    func didTapMore() {
        // TODO
    }

    func didTapLike() {
        state = state == .approved ? .liked : .approved
    }
}
