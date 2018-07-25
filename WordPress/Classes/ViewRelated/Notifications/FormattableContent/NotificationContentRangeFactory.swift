
protocol ContentRangeFactory {
    static func contentRange(from dictionary: [String: AnyObject]) -> FormattableContentRange?
}

extension ContentRangeFactory {
    static func rangeFrom(_ dictionary: [String: AnyObject]) -> NSRange? {
        guard let indices = dictionary[RangeKeys.indices] as? [Int],
            let start = indices.first,
            let end = indices.last else {
                return nil
        }
        return NSMakeRange(start, end - start)
    }

    static func kindString(from dictionary: [String: AnyObject]) -> String? {
        return dictionary[RangeKeys.rawType] as? String
    }
}

private enum RangeKeys {
    static let rawType = "type"
    static let url = "url"
    static let indices = "indices"
    static let id = "id"
    static let value = "value"
    static let siteId = "site_id"
    static let postId = "post_id"
}

struct NotificationContentRangeFactory: ContentRangeFactory {
    static func contentRange(from dictionary: [String: AnyObject]) -> FormattableContentRange? {
        guard let range = rangeFrom(dictionary) else {
            return nil
        }
        let properties = propertiesFrom(dictionary, with: range)

        if let kind = kindString(from: dictionary) {
            return contentRange(ofKind: kind, with: properties, from: dictionary)
        }

        return contentRangeWithoutKindSpecified(with: properties, from: dictionary)
    }

    private static func propertiesFrom(_ dictionary: [String: AnyObject], with range: NSRange) -> NotificationContentRange.Properties {
        var properties = NotificationContentRange.Properties(range: range)

        properties.siteID = dictionary[RangeKeys.siteId] as? NSNumber
        properties.postID = dictionary[RangeKeys.postId] as? NSNumber

        if let url = dictionary[RangeKeys.url] as? String {
            properties.url = URL(string: url)
        }
        return properties
    }

    private static func contentRange(ofKind type: String, with properties: NotificationContentRange.Properties, from dictionary: [String: AnyObject]) -> FormattableContentRange? {
        var properties = properties
        let kind = FormattableRangeKind(type)

        switch kind {
        case .comment:
            let commentID = dictionary[RangeKeys.id] as? NSNumber
            return FormattableCommentRange(commentID: commentID, properties: properties)
        case .noticon:
            guard let value = dictionary[RangeKeys.value] as? String else {
                fallthrough
            }
            return FormattableNoticonRange(value: value, range: properties.range)
        case .post:
            properties.postID = dictionary[RangeKeys.id] as? NSNumber
            return NotificationContentRange(kind: kind, properties: properties)
        case .site:
            properties.siteID = dictionary[RangeKeys.id] as? NSNumber
            return NotificationContentRange(kind: kind, properties: properties)
        case .user:
            properties.userID = dictionary[RangeKeys.id] as? NSNumber
            return NotificationContentRange(kind: kind, properties: properties)
        default:
            return NotificationContentRange(kind: kind, properties: properties)
        }
    }

    private static func contentRangeWithoutKindSpecified(with properties: NotificationContentRange.Properties, from dictionary: [String: AnyObject]) -> NotificationContentRange? {
        if containsSiteID(dictionary) {
            return NotificationContentRange(kind: .site, properties: properties)
        }
        if containsValidURL(dictionary) {
            return NotificationContentRange(kind: .link, properties: properties)
        }
        return nil
    }

    private static func containsSiteID(_ dictionary: [String: AnyObject]) -> Bool {
        return (dictionary[RangeKeys.siteId] as? NSNumber) != nil
    }

    private static func containsValidURL(_ dictionary: [String: AnyObject]) -> Bool {
        let urlString = dictionary[RangeKeys.url] as? String ?? ""
        return URL(string: urlString) != nil
    }

    enum RangeKeys {
        static let rawType = "type"
        static let url = "url"
        static let indices = "indices"
        static let id = "id"
        static let value = "value"
        static let siteId = "site_id"
        static let postId = "post_id"
    }
}
