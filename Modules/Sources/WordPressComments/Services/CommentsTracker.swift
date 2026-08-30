public enum CommentsTrackedEvent: Equatable, Sendable {
    case detailViewed(commentID: Int64, postID: Int64)
}

public protocol CommentsTracker: Sendable {
    func track(_ event: CommentsTrackedEvent)
}
