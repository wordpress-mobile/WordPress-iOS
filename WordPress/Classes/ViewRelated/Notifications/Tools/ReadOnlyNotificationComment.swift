import CoreData
import FormattableContentKit
import WordPressData

/// A read-only copy of a comment notification's comment, built from the notification's own content.
///
/// Use it when the app can't load the comment from its site, for example because the site is private and
/// the user isn't a member. The notification still carries the comment, its author and what it replies to.
///
/// `comment` and `parentComment` aren't inserted into any Core Data context, so they can't be saved or turn
/// up in fetches.
struct ReadOnlyNotificationComment {
    let comment: Comment

    /// The comment that `comment` replies to, or `nil` for a reply to a post. Only its author and an
    /// excerpt are known.
    let parentComment: Comment?

    /// The web address of the user's reply to `comment`, or `nil` if they haven't replied.
    let replyURL: URL?

    /// Returns `nil` when the notification has no comment to show.
    init?(notification: WordPressData.Notification) {
        guard
            let entity = notification.entity.managedObjectModel.entitiesByName[Comment.classNameWithoutNamespaces()],
            let group = notification.contentGroup(ofKind: .comment),
            let commentBlock: FormattableCommentContent = group.blockOfKind(.comment),
            let commentID = notification.metaCommentID ?? commentBlock.metaCommentID,
            let rawCommentBlock = notification.body(ofType: .comment),
            let text = rawCommentBlock["text"] as? String,
            !text.isEmpty
        else {
            return nil
        }
        let author: FormattableUserContent? = group.blockOfKind(.user)

        let comment = Comment(entity: entity, insertInto: nil)
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

        let replyURL = notification.metaReplyID.flatMap { notification.linkToComment(withID: $0) }
        if let replyID = notification.metaReplyID, replyURL != nil {
            comment.replyID = replyID.int32Value
        }

        self.comment = comment
        self.parentComment = Self.makeParentComment(of: comment, entity: entity, from: notification)
        self.replyURL = replyURL
    }

    /// Builds the parent comment from the notification header, which names its author and quotes its start.
    private static func makeParentComment(
        of comment: Comment,
        entity: NSEntityDescription,
        from notification: WordPressData.Notification
    ) -> Comment? {
        guard comment.hasParentComment(), let header = notification.headerContentGroup else {
            return nil
        }
        let authorBlock: NotificationTextContent? = header.blockOfKind(.image)
        let excerptBlock: NotificationTextContent? = header.blockOfKind(.text)

        let parent = Comment(entity: entity, insertInto: nil)
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

    /// The web address of a comment the notification links to, such as the "You replied to this comment." line.
    func linkToComment(withID commentID: NSNumber) -> URL? {
        bodyContentGroups.lazy
            .flatMap(\.blocks)
            .flatMap(\.ranges)
            .compactMap { $0 as? NotificationCommentRange }
            .first { $0.commentID == commentID }?
            .url
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
