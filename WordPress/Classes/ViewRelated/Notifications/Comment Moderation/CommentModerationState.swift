enum CommentModerationState: Equatable {
    case pending
    case approved(liked: Bool)
    case spam
    case trash
}
