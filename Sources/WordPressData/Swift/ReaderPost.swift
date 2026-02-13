import Foundation
import WordPressShared

public enum SourceAttributionStyle: Int {
    case none
    case post
    case site
}

@objc(ReaderPost)
public class ReaderPost: BasePost {

    /// Used for tracking when a post is rendered (displayed), and bumping the train tracks rendered event.
    public var rendered: Bool = false

    public override func didSave() {
        super.didSave()

        // A ReaderCard can have either a post, or a list of topics, but not both.
        // Since this card has a post, we can confidently set `topics` to NULL.
        if responds(to: #selector(getter: card)), let managedObjectContext, let firstCard = card?.first {
            firstCard.topics = nil
            ContextManager.shared.save(managedObjectContext)
        }
    }

    override public var featuredImageURL: URL? {
        if let featuredImage, !featuredImage.isEmpty {
            return URL(string: featuredImage)
        }
        return nil
    }

    public func contentPreviewForDisplay() -> String? {
        return summary
    }
}

extension ReaderPost {
    public var isCrossPost: Bool {
        crossPostMeta != nil
    }

    public var isP2Type: Bool {
        let id = organizationID.intValue
        guard let type = SiteOrganizationType(rawValue: id) else { return false }
        return type == .p2 || type == .automattic
    }
}

extension ReaderPost {

    public func blogNameForDisplay() -> String? {
        if let blogName, !blogName.isEmpty {
            return blogName.replacing(/\s+/, with: " ")
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

    public func tagsForDisplay() -> [String] {
        guard let tags, !tags.isEmpty else {
            return []
        }
        return tags.components(separatedBy: ", ")
    }

    public func authorForDisplay() -> String? {
        if let name = self.authorDisplayName, !name.isEmpty {
            return name
        }

        return author
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    public func featuredImageURLForDisplay() -> URL? {
        return featuredImageURL
    }

    public func avatarURLForDisplay() -> URL? {
        authorAvatarURL.flatMap(URL.init(string:))
    }

    public func sourceAuthorNameForDisplay() -> String? {
        sourceAttribution?.authorName
    }

    public func sourceAttributionStyle() -> SourceAttributionStyle {
        guard let sourceAttribution else {
            return .none
        }

        if sourceAttribution.attributionType == SourcePostAttribution.post {
            return .post
        } else if sourceAttribution.attributionType == SourcePostAttribution.site {
            return .site
        }

        return .none
    }

    public func sourceAvatarURLForDisplay() -> URL? {
        sourceAttribution?.avatarURL.flatMap(URL.init(string:))
    }

    public func sourceBlogNameForDisplay() -> String? {
        return sourceAttribution?.blogName
    }

    public func contentIncludesFeaturedImage() -> Bool {
        guard let imageURL = featuredImageURL else {
            return false
        }

        var featuredImage = imageURL.absoluteString

        // Remove any query string params if needed (e.g. resize values)
        if let questionMarkRange = featuredImage.range(of: "?", options: .backwards) {
            featuredImage = String(featuredImage[..<questionMarkRange.lowerBound])
        }

        // One URL might be http and the other https, so don't include the protocol in the check.
        if let scheme = imageURL.scheme, !scheme.isEmpty {
            let length = scheme.count + 3 // protocol + ://
            let startIndex = featuredImage.index(featuredImage.startIndex, offsetBy: length)
            featuredImage = String(featuredImage[startIndex...])
        }

        guard let content = contentForDisplay(), !content.isEmpty else {
            return false
        }

        return content.contains(featuredImage)
    }

    @objc
    public func railcarDictionary() -> [String: Any]? {
        guard let jsonData = railcar?.data(using: .utf8) else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    }
}
