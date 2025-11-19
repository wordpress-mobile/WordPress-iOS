import Foundation
import WordPressShared

extension ReaderPost {

    @objc public override var featuredImageURL: URL? {
        if !self.featuredImage.isEmpty {
            return URL(string: self.featuredImage)
        }
        return nil
    }
}

@objc extension ReaderPost {

    public override func blogNameForDisplay() -> String? {
        if let blogName, !blogName.isEmpty {
            return blogName
        }
        return URL(string: blogURL ?? "")?.host
    }

    public override func titleForDisplay() -> String {
        let title = postTitle?.trimmingCharacters(in: .whitespaces).stringByDecodingXMLCharacters()
        guard let title, !title.isEmpty else {
            return ""
        }
        return title
    }

    public override func tagsForDisplay() -> [String]? {
        guard let tags, !tags.isEmpty else {
            return []
        }

        let tagArray = tags.components(separatedBy: ", ")
        return tagArray.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    public override func authorForDisplay() -> String? {
        return authorString()
    }

    public override func dateForDisplay() -> Date? {
        return dateCreated
    }

    public override func contentPreviewForDisplay() -> String? {
        return summary
    }

    public override func featuredImageURLForDisplay() -> URL? {
        return featuredImageURL
    }

    public func avatarURLForDisplay() -> URL? {
        authorAvatarURL.flatMap(URL.init(string:))
    }
}
