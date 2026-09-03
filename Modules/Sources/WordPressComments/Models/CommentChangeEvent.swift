import Foundation

/// Emitted after a moderation request commits, so every loaded
/// `CommentsListViewModel` can keep its in-memory items in sync without a
/// full refetch.
enum CommentChangeEvent: Equatable, Sendable {
    case statusChanged(id: Int64, to: CommentListItem.Status)
    case deleted(id: Int64)
}

extension CommentChangeEvent {
    /// The comment the event is about, used by detail screens to filter the
    /// coordinator's event stream.
    var commentID: Int64 {
        switch self {
        case .statusChanged(let id, _): id
        case .deleted(let id): id
        }
    }
}
