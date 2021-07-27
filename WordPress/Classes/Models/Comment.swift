import Foundation

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

extension Comment {

    @objc static func descriptionFor(_ commentStatus: CommentStatusType) -> String {
        return commentStatus.description
    }

    @objc func authorUrlForDisplay() -> String {
        return authorURL()?.host ?? String()
    }

    @objc func isApproved() -> Bool {
        return status.isEqual(to: CommentStatusType.approved.description)
    }

    @objc func isReadOnly() -> Bool {
        // If the current user cannot moderate the comment, they can only Like and Reply if the comment is Approved.
        return (blog.isHostedAtWPcom || blog.isAtomic()) && !canModerate && !isApproved()
    }

    @objc func sectionIdentifier() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: dateCreated)
    }

    func numberOfLikes() -> Int {
        return likeCount.intValue
    }

    func hasAuthorUrl() -> Bool {
        return author_url != nil && !author_url.isEmpty
    }

}

private extension Comment {

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
            displayAuthor = author_email.trim()
        }

        return displayAuthor.isEmpty ? String() : displayAuthor
    }

    // Used in Comment details (non-threaded)
    public func contentForDisplay() -> String {
        return rawContent
    }

    // Used in Comments list
    public func contentPreviewForDisplay() -> String {
        return rawContent
    }

    public func avatarURLForDisplay() -> URL? {
        return URL(string: authorAvatarURL)
    }

    public func gravatarEmailForDisplay() -> String {
        return author_email.trim() ?? String()
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    public func authorURL() -> URL? {
        return URL(string: author_url)
    }

}
