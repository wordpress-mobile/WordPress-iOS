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
}


private extension Comment {

    func decodedContent() -> String {
        return content.stringByDecodingXMLCharacters().trim().strippingHTML().normalizingWhitespace() ?? String()
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
        let title = postTitle.stringByDecodingXMLCharacters()

        guard !title.isEmpty else {
            return NSLocalizedString("(No Title)", comment: "Empty Post Title")
        }

        return title
    }

    public func authorForDisplay() -> String {
        var displayAuthor = authorName().stringByDecodingXMLCharacters().trim()

        if displayAuthor.isEmpty {
            displayAuthor = author_email.trim()
        }

        return displayAuthor.isEmpty ? String() : displayAuthor
    }

    public func blogNameForDisplay() -> String? {
        return author_url
    }

    public func statusForDisplay() -> String {
        var status = Comment.title(forStatus: status) ?? ""
        if status.isEqual(to: NSLocalizedString("Comments", comment: "Comment status")) {
            status = ""
        }

        return status
    }

    public func contentForDisplay() -> String {
        return decodedContent()
    }

    public func contentPreviewForDisplay() -> String {
        return decodedContent()
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
