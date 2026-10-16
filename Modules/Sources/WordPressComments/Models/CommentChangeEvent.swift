import Foundation

/// Emitted after a moderation request commits, so every loaded
/// `CommentsListViewModel` can keep its in-memory items in sync without a
/// full refetch.
enum CommentChangeEvent: Equatable, Sendable {
    case statusChanged(id: Int64, to: CommentListItem.Status)
    case deleted(id: Int64)
    /// A reply was created under `parentID`. Loaded tabs matching the reply's
    /// own status (not the parent's) insert the row at the top.
    case replyCreated(parentID: Int64, reply: CommentListItem)
    /// A comment's content was edited. Carries `contentRaw` so an open detail
    /// screen keeps a fresh raw value for a subsequent edit; list rows only
    /// need `contentHTML` to refresh their snippet.
    case contentChanged(id: Int64, contentHTML: String, contentRaw: String?)
}

extension CommentChangeEvent {
    /// The comment the event is about, used by detail screens to filter the
    /// coordinator's event stream.
    var commentID: Int64 {
        switch self {
        case .statusChanged(let id, _): id
        case .deleted(let id): id
        case .replyCreated(let parentID, _): parentID
        case .contentChanged(let id, _, _): id
        }
    }
}
