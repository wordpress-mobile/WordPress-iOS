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
        case other
    }

    let id: Int64
    let authorName: String
    let avatarURL: URL?
    let postID: Int64
    let snippet: String
    let date: Date
    let status: Status

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
        authorName = comment.authorName.isEmpty ? Strings.anonymousAuthor : comment.authorName
        // The avatar subscript yields a double optional (missing key vs. a
        // stored nil); flatten it before building the URL.
        avatarURL = comment.authorAvatarUrls[.size96].flatMap { $0 }.flatMap(URL.init(string:))
        postID = comment.post
        snippet = comment.content.rendered
            .makePlainText()
            .replacingOccurrences(of: "\n", with: " ")
        date = comment.dateGmt
        status = Status(comment.status)
    }
}

private extension CommentListItem.Status {
    init(_ status: CommentStatus) {
        switch status {
        case .hold: self = .pending
        case .approved: self = .approved
        case .spam: self = .spam
        case .trash: self = .trash
        case .custom: self = .other
        }
    }
}
