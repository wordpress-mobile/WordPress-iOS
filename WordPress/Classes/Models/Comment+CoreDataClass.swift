import Foundation
import CoreData

@objc(Comment)
public class Comment: NSManagedObject {

    @objc static func descriptionFor(_ commentStatus: CommentStatusType) -> String {
        return commentStatus.description
    }

    @objc func authorUrlForDisplay() -> String {
        return authorURL()?.host ?? String()
    }

    @objc func contentForEdit() -> String {
        return availableContent()
    }

    @objc func isApproved() -> Bool {
        return status.isEqual(to: CommentStatusType.approved.description)
    }

    @objc func isReadOnly() -> Bool {
        guard let blog = blog else {
            return true
        }

        // If the current user cannot moderate the comment, they can only Like and Reply if the comment is Approved.
        return (blog.isHostedAtWPcom || blog.isAtomic()) && !canModerate && !isApproved()
    }

    // This can be removed when `unifiedCommentsAndNotificationsList` is permanently enabled
    // as it's replaced by Comment+Interface:relativeDateSectionIdentifier.
    @objc func sectionIdentifier() -> String? {
        guard let dateCreated = dateCreated else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: dateCreated)
    }

    @objc func commentURL() -> URL? {
        guard !link.isEmpty else {
            return nil
        }

        return URL(string: link)
    }

    @objc func deleteWillBePermanent() -> Bool {
        return status.isEqual(to: Comment.descriptionFor(.spam)) || status.isEqual(to: Comment.descriptionFor(.unapproved))
    }

    func numberOfLikes() -> Int {
        return Int(likeCount)
    }

    func hasAuthorUrl() -> Bool {
        return !author_url.isEmpty
    }

    func hasParentComment() -> Bool {
        return parentID > 0
    }

}

private extension Comment {

    func decodedContent() -> String {
        // rawContent/content contains markup for Gutenberg comments. Remove it so it's not displayed.
        return availableContent().stringByDecodingXMLCharacters().trim().strippingHTML().normalizingWhitespace() ?? String()
    }

    func authorName() -> String {
        return !author.isEmpty ? author : NSLocalizedString("Anonymous", comment: "the comment has an anonymous author.")
    }

    // The REST endpoint response contains both content and rawContent.
    // The XMLRPC endpoint response contains only content.
    // So for Comment display and Comment editing, use which content the Comment has.
    // The result is WP sites will use rawContent, self-hosted will use content.
    func availableContent() -> String {
        if !rawContent.isEmpty {
            return rawContent
        }

        if !content.isEmpty {
            return content
        }

        return String()
    }

}

extension Comment: PostContentProvider {

    public func titleForDisplay() -> String {
        let title = post?.postTitle ?? postTitle
        return !title.isEmpty ? title.stringByDecodingXMLCharacters() : NSLocalizedString("(No Title)", comment: "Empty Post Title")
    }

    public func authorForDisplay() -> String {
        let displayAuthor = authorName().stringByDecodingXMLCharacters().trim()
        return !displayAuthor.isEmpty ? displayAuthor : gravatarEmailForDisplay()
    }

    // Used in Comment details (non-threaded)
    public func contentForDisplay() -> String {
        return decodedContent()
    }

    // Used in Comments list (non-threaded)
    public func contentPreviewForDisplay() -> String {
        return decodedContent()
    }

    public func avatarURLForDisplay() -> URL? {
        return !authorAvatarURL.isEmpty ? URL(string: authorAvatarURL) : nil
    }

    public func gravatarEmailForDisplay() -> String {
        let displayEmail = author_email.trim()
        return !displayEmail.isEmpty ? displayEmail : String()
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    @objc public func authorURL() -> URL? {
        return !author_url.isEmpty ? URL(string: author_url) : nil
    }

}

// When CommentViewController and CommentService are converted to Swift, this can be simplified to a String enum.
@objc enum CommentStatusType: Int {
    case pending
    case approved
    case unapproved
    case spam
    // Draft status is for comments that have not yet been successfully published/uploaded.
    // We can use this status to restore comment replies that the user has written.
    case draft

    var description: String {
        switch self {
        case .pending:
            return "hold"
        case .approved:
            return "approve"
        case .unapproved:
            return "trash"
        case .spam:
            return "spam"
        case .draft:
            return "draft"
        }
    }

    static func typeForStatus(_ status: String?) -> CommentStatusType? {
        switch status {
        case "hold":
            return .pending
        case "approve":
            return .approved
        case "trash":
            return .unapproved
        case "spam":
            return .spam
        case "draft":
            return .draft
        default:
            return nil
        }
    }
}
