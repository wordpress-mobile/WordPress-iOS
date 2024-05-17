enum CommentModerationState: Equatable {
    case pending
    case approved(liked: Bool)
    case spam
    case trash

    init(comment: Comment) {
        switch comment.status {
        case "approve":
            self = .approved(liked: comment.isLiked)
        case "hold":
            self = .pending
        case "spam":
            self = .spam
        case "trash":
            self = .trash
        default:
            // Defaulting to `pending` if for some reason
            // the status isn't one of the defined cases.
            self = .pending
        }
    }
}
