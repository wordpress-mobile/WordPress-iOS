import Foundation

private extension Comment {
    func decodedContent() -> String {
        return content.stringByDecodingXMLCharacters().trim().strippingHTML().normalizingWhitespace() ?? String()
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
        var displayAuthor = author.stringByDecodingXMLCharacters().trim()

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
        if status.isEqual(to: NSLocalizedString("Comments", comment: "")) {
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
