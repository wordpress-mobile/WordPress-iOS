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
        return rawContent ?? content ?? String()
    }

    @objc func isApproved() -> Bool {
        return status?.isEqual(to: CommentStatusType.approved.description) ?? false
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
        guard let commentUrl = link,
              !commentUrl.isEmpty else {
            return nil
        }

        return URL(string: commentUrl)
    }

    func numberOfLikes() -> Int {
        return Int(likeCount)
    }

    func hasAuthorUrl() -> Bool {
        guard let url = author_url,
              !url.isEmpty else {
            return false
        }

        return true
    }

}

private extension Comment {

    func decodedContent() -> String {
        guard let displayContent = rawContent ?? content else {
            return String()
        }
        // rawContent/content contains markup for Gutenberg comments. Remove it so it's not displayed.
        return displayContent.stringByDecodingXMLCharacters().trim().strippingHTML().normalizingWhitespace() ?? String()
    }

    func authorName() -> String {
        guard let authorName = author,
              !authorName.isEmpty else {
            return NSLocalizedString("Anonymous", comment: "the comment has an anonymous author.")
        }

        return authorName
    }

}

extension Comment: PostContentProvider {

    public func titleForDisplay() -> String {
        guard let title = post?.postTitle ?? postTitle,
              !title.isEmpty else {
            return NSLocalizedString("(No Title)", comment: "Empty Post Title")
        }

        return title.stringByDecodingXMLCharacters()
    }

    public func authorForDisplay() -> String {
        var displayAuthor = authorName().stringByDecodingXMLCharacters().trim()

        if displayAuthor.isEmpty {
            displayAuthor = author_email?.trim() ?? String()
        }

        return displayAuthor
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
        guard let url = authorAvatarURL,
              !url.isEmpty else {
            return nil
        }
        return URL(string: url)
    }

    public func gravatarEmailForDisplay() -> String {
        return author_email?.trim() ?? String()
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    public func authorURL() -> URL? {
        guard let url = author_url,
              !url.isEmpty else {
            return nil
        }
        return URL(string: url)
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
}
