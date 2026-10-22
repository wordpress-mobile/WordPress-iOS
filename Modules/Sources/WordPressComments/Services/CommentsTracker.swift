public enum CommentsTrackedEvent: Equatable, Sendable {
    case detailViewed(commentID: Int64, postID: Int64)
    case approved(commentID: Int64, postID: Int64)
    case unapproved(commentID: Int64, postID: Int64)
    case spammed(commentID: Int64, postID: Int64)
    case trashed(commentID: Int64, postID: Int64)
    // Permanent delete: legacy has no analytics event; deliberately untracked.
    /// A reply was successfully created, matching legacy's reply-sent event.
    case repliedTo(commentID: Int64, postID: Int64)
    /// The content editor was opened for a comment, matching legacy's
    /// edit-entry event.
    case editorOpened(commentID: Int64, postID: Int64)
    /// A comment's content was successfully edited, matching legacy's
    /// edit-saved event.
    case edited(commentID: Int64, postID: Int64)
}

public protocol CommentsTracker: Sendable {
    func track(_ event: CommentsTrackedEvent)
}
