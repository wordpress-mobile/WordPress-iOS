enum CommentModerationState: CaseIterable {
    case pending
    case approved
    case liked
    case trash

    init?(comment: Comment) {
        switch comment.status {
        case "approve":
            self = .approved
        case "pending":
            self = .pending
        case "trash":
            self = .trash
        default:
            return nil
        }
    }
}
