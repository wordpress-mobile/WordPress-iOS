import Foundation
import WordPressShared

@objc extension BasePost {

    public func titleForDisplay() -> String {
        let title = postTitle?.trimmingCharacters(in: .whitespaces)
        guard let title, !title.isEmpty else {
            return NSLocalizedString("(no title)", comment: "Placeholder text for missing post title")
        }
        return title.stringByDecodingXMLCharacters()
    }

    public func authorForDisplay() -> String? {
        return author?.stringByDecodingXMLCharacters()
    }

    public func blogNameForDisplay() -> String? {
        return ""
    }

    public func contentForDisplay() -> String? {
        return content
    }

    public func contentPreviewForDisplay() -> String? {
        return content
    }

    public func gravatarEmailForDisplay() -> String? {
        return nil
    }

    public func avatarURLForDisplay() -> URL? {
        return nil
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    public func featuredImageURLForDisplay() -> URL? {
        return nil
    }

    public func authorURL() -> URL? {
        return nil
    }

    public func tagsForDisplay() -> [String]? {
        return nil
    }
}
