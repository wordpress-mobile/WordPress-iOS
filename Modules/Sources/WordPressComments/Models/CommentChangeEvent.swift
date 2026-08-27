import Foundation

/// Emitted after a moderation request commits, so every loaded
/// `CommentsListViewModel` can keep its in-memory items in sync without a
/// full refetch.
enum CommentChangeEvent: Equatable, Sendable {
    case statusChanged(id: Int64, to: CommentListItem.Status)
    case deleted(id: Int64)
    /// A reply was created under `parentID`. Carries the reply's own status
    /// (not the parent's) so loaded tabs can decide whether it belongs to
    /// them; stales rather than inserts because a paged list cannot know the
    /// reply's correct position.
    case replyCreated(parentID: Int64, replyStatus: CommentListItem.Status)
}

extension CommentChangeEvent {
    /// The comment the event is about, used by detail screens to filter the
    /// coordinator's event stream.
    var commentID: Int64 {
        switch self {
        case .statusChanged(let id, _): id
        case .deleted(let id): id
        case .replyCreated(let parentID, _): parentID
        }
    }
}
