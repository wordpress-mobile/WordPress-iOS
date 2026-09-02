public enum CommentsTrackedEvent: Equatable, Sendable {
    case detailViewed(commentID: Int64, postID: Int64)
    case approved(commentID: Int64, postID: Int64)
    case unapproved(commentID: Int64, postID: Int64)
    case spammed(commentID: Int64, postID: Int64)
    case trashed(commentID: Int64, postID: Int64)
    // Permanent delete: legacy has no analytics event; deliberately untracked.
}

public protocol CommentsTracker: Sendable {
    func track(_ event: CommentsTrackedEvent)
}
