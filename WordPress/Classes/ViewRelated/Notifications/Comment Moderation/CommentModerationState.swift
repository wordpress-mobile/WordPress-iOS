enum CommentModerationState: Equatable {
    case pending
    case approved(liked: Bool)
    case spam
    case trash

    init?(comment: Comment) {
        switch comment.status {
        case "approve":
            self = .approved(liked: false)
        case "pending":
            self = .pending
        case "spam":
            self = .spam
        case "trash":
            self = .trash
        default:
            return nil
        }
    }
}
