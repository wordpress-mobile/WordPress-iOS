import Foundation
import WordPressAPI
import WordPressShared

/// Value type consumed by the detail/moderation screen, mapped from either
/// wordpress-rs view- or edit-context wire types. Edit context adds the
/// author's email and IP address, which view context omits.
struct CommentDetail: Equatable, Sendable {
    let id: Int64
    let authorName: String
    let avatarURL: URL?
    let authorURL: URL?
    let authorEmail: String? // edit context only
    let authorIP: String? // edit context only
    let postID: Int64
    let parentID: Int64? // nil when the wire value is 0 (top-level)
    let contentHTML: String
    let link: URL?
    let date: Date
    var status: CommentListItem.Status
    /// False when the fetch fell back to view context (no email/IP; M3 edit
    /// needs content.raw, also unavailable).
    let hasEditContext: Bool

    init(comment: CommentWithViewContext) {
        self.init(
            id: comment.id,
            authorName: comment.authorName,
            avatarURL: comment.authorAvatarUrls.avatarURL,
            authorURL: comment.authorUrl,
            authorEmail: nil,
            authorIP: nil,
            postID: comment.post,
            parentID: comment.parent,
            contentHTML: comment.content.rendered,
            link: comment.link,
            date: comment.dateGmt,
            status: CommentListItem.Status(comment.status),
            hasEditContext: false
        )
    }

    init(comment: CommentWithEditContext) {
        self.init(
            id: comment.id,
            authorName: comment.authorName,
            avatarURL: comment.authorAvatarUrls.avatarURL,
            authorURL: comment.authorUrl,
            authorEmail: comment.authorEmail,
            authorIP: comment.authorIp,
            postID: comment.post,
            parentID: comment.parent,
            contentHTML: comment.content.rendered,
            link: comment.link,
            date: comment.dateGmt,
            status: CommentListItem.Status(comment.status),
            hasEditContext: true
        )
    }

    private init(
        id: Int64,
        authorName: String,
        avatarURL: URL?,
        authorURL: String,
        authorEmail: String?,
        authorIP: String?,
        postID: Int64,
        parentID: Int64,
        contentHTML: String,
        link: String,
        date: Date,
        status: CommentListItem.Status,
        hasEditContext: Bool
    ) {
        self.id = id
        self.authorName = authorName.nonEmptyString() ?? Strings.anonymousAuthor
        self.avatarURL = avatarURL
        // wordpress-rs represents an absent value as an empty string rather
        // than nil; normalize before constructing a URL.
        self.authorURL = authorURL.nonEmptyString().flatMap { URL(string: $0) }
        self.authorEmail = authorEmail.flatMap { $0.nonEmptyString() }
        self.authorIP = authorIP.flatMap { $0.nonEmptyString() }
        self.postID = postID
        self.parentID = parentID == 0 ? nil : parentID
        self.contentHTML = contentHTML
        self.link = link.nonEmptyString().flatMap { URL(string: $0) }
        self.date = date
        self.status = status
        self.hasEditContext = hasEditContext
    }
}

#if DEBUG
extension CommentDetail {
    /// Preview-only builder. Production paths construct `CommentDetail` from a
    /// wire type, but SwiftUI previews can't reach the uniffi builders, so this
    /// assembles one from plain values.
    static func preview(
        id: Int64 = 1,
        status: CommentListItem.Status = .pending,
        parentID: Int64 = 0,
        contentHTML: String =
            "<p>Really appreciate the detailed writeup. This is exactly the kind of review I was hoping to find before committing to the upgrade.</p>",
        hasEditContext: Bool = true
    ) -> CommentDetail {
        CommentDetail(
            id: id,
            authorName: "Priya Nair",
            avatarURL: nil,
            authorURL: "https://example.com",
            authorEmail: hasEditContext ? "priya@example.com" : "",
            authorIP: hasEditContext ? "203.0.113.4" : "",
            postID: 10,
            parentID: parentID,
            contentHTML: contentHTML,
            link: "https://example.com/?p=10#comment-\(id)",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            status: status,
            hasEditContext: hasEditContext
        )
    }
}
#endif
