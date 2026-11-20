import CoreData
import FormattableContentKit
import WordPressData

/// A read-only copy of a comment notification's comment, built from the notification's own content.
///
/// Use it when the app can't load the comment from its site, for example because the site is private and
/// the user isn't a member. The notification still carries the comment, its author and what it replies to.
///
/// Keep this object alive while `comment` and `parentComment` are in use. They live in its private context,
/// and once that context is gone every property reads back empty.
final class ReadOnlyNotificationComment {
    let comment: Comment

    /// The comment that `comment` replies to, or `nil` for a reply to a post. Only its author and an
    /// excerpt are known.
    let parentComment: Comment?

    /// Holds `comment` and `parentComment`. It is never saved, so the copies never reach the database.
    private let context: NSManagedObjectContext

    /// Returns `nil` when the notification has no comment to show.
    init?(notification: WordPressData.Notification, mainContext: NSManagedObjectContext) {
        guard let group = notification.contentGroup(ofKind: .comment),
            let commentBlock: FormattableCommentContent = group.blockOfKind(.comment),
            let commentID = notification.metaCommentID ?? commentBlock.metaCommentID,
            let rawCommentBlock = notification.body(ofType: .comment),
            let text = rawCommentBlock["text"] as? String,
            !text.isEmpty
        else {
            return nil
        }
        let author: FormattableUserContent? = group.blockOfKind(.user)

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = mainContext

        let comment = Comment(context: context)
        comment.commentID = commentID.int32Value
        comment.postID = notification.metaPostID?.int32Value ?? 0
        comment.parentID = notification.metaParentID?.int32Value ?? 0
        comment.content = NotificationCommentHTML.html(
            text: text,
            ranges: rawCommentBlock["ranges"] as? [[String: Any]] ?? []
        )
        comment.dateCreated = notification.timestampAsDate
        comment.link = notification.url ?? ""
        comment.postTitle = notification.linkedPostTitle ?? ""
        comment.status = (commentBlock.isCommentApproved ? CommentStatusType.approved : .pending).description
        comment.authorID = notification.metaCommentAuthorID?.int32Value ?? 0
        comment.author = author?.text ?? ""
        comment.authorAvatarURL = author?.media.first?.mediaURL?.absoluteString ?? ""
        comment.author_url = author?.metaLinksHome?.absoluteString ?? ""

        self.comment = comment
        self.parentComment = Self.makeParentComment(of: comment, from: notification, in: context)
        self.context = context
    }

    /// Builds the parent comment from the notification header, which names its author and quotes its start.
    private static func makeParentComment(
        of comment: Comment,
        from notification: WordPressData.Notification,
        in context: NSManagedObjectContext
    ) -> Comment? {
        guard comment.hasParentComment(), let header = notification.headerContentGroup else {
            return nil
        }
        let authorBlock: NotificationTextContent? = header.blockOfKind(.image)
        let excerptBlock: NotificationTextContent? = header.blockOfKind(.text)

        let parent = Comment(context: context)
        parent.commentID = comment.parentID
        parent.postID = comment.postID
        parent.author = authorBlock.flatMap { $0.text(ofFirstRange: .user) ?? $0.text } ?? ""
        parent.authorAvatarURL = authorBlock?.media.first?.mediaURL?.absoluteString ?? ""
        parent.content = NotificationCommentHTML.html(text: excerptBlock?.text ?? "", ranges: [])
        return parent
    }
}

private extension WordPressData.Notification {
    /// The title of the post this notification is about, from the first post link in its header or subject.
    var linkedPostTitle: String? {
        let blocks = (headerContentGroup?.blocks ?? []) + (subjectContentGroup?.blocks ?? [])
        return blocks.lazy.compactMap { $0.text(ofFirstRange: .post) }.first
    }
}

private extension FormattableContent {
    func text(ofFirstRange kind: FormattableRangeKind) -> String? {
        guard let text,
            let range = ranges.first(where: { $0.kind == kind })?.range,
            let textRange = Range(range, in: text)
        else {
            return nil
        }
        return String(text[textRange])
    }
}
