import Foundation
import WordPressAPI
import WordPressShared

/// Value type consumed by the list UI, mapped once from the wordpress-rs
/// response type so views and tests never depend on uniffi types. Mapping is
/// also where wordpress-rs's empty-string-instead-of-nil quirk is normalized.
struct CommentListItem: Identifiable, Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case pending
        case approved
        case spam
        case trash
        case other(String)
    }

    let id: Int64
    let authorName: String
    let avatarURL: URL?
    let postID: Int64
    let snippet: String
    let date: Date
    var status: Status

    init(
        id: Int64,
        authorName: String,
        avatarURL: URL?,
        postID: Int64,
        snippet: String,
        date: Date,
        status: Status
    ) {
        self.id = id
        self.authorName = authorName
        self.avatarURL = avatarURL
        self.postID = postID
        self.snippet = snippet
        self.date = date
        self.status = status
    }

    init(comment: CommentWithViewContext) {
        id = comment.id
        authorName = comment.authorName.nonEmptyString() ?? Strings.anonymousAuthor
        avatarURL = comment.authorAvatarUrls.avatarURL
        postID = comment.post
        snippet = Self.snippet(fromHTML: comment.content.rendered)
        date = comment.dateGmt
        status = Status(comment.status)
    }

    /// Row-shaped projection of a fetched detail (used for the parent preview
    /// strip), so the snippet rule stays in one place.
    init(detail: CommentDetail) {
        self.init(
            id: detail.id,
            authorName: detail.authorName,
            avatarURL: detail.avatarURL,
            postID: detail.postID,
            snippet: Self.snippet(fromHTML: detail.contentHTML),
            date: detail.date,
            status: detail.status
        )
    }

    /// Single-line plain-text preview of comment HTML.
    static func snippet(fromHTML html: String) -> String {
        html.makePlainText().replacingOccurrences(of: "\n", with: " ")
    }
}

extension Dictionary where Key == UserAvatarSize, Value == String? {
    /// The 96pt avatar URL. The subscript yields a double optional (missing
    /// key vs. a stored nil); flatten it before building the URL.
    var avatarURL: URL? {
        self[.size96].flatMap { $0 }.flatMap(URL.init(string:))
    }
}

extension CommentListItem.Status {
    init(_ status: CommentStatus) {
        switch status {
        case .hold: self = .pending
        case .approved: self = .approved
        case .spam: self = .spam
        case .trash: self = .trash
        case .custom(let raw): self = .other(raw)
        }
    }
}
