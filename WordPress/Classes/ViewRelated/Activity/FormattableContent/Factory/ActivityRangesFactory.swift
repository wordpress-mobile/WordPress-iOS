
struct ActivityRangesFactory: ContentRangeFactory {
    static func contentRange(from dictionary: [String : AnyObject]) -> FormattableContentRange? {
        guard let range = rangeFrom(dictionary) else {
            return nil
        }
        let url = urlFrom(dictionary, withKey: RangeKeys.url)

        guard let kind = kindString(from: dictionary) else {
            return ActivityRange(range: range, url: url)
        }
        let rangeKind = FormattableRangeKind(kind)

        return createRangeOfKind(rangeKind, url: url, range: range, dictionary: dictionary)
    }

    private static func createRangeOfKind(_ kind: FormattableRangeKind, url: URL?, range: NSRange, dictionary: [String: AnyObject]) -> FormattableContentRange {
        switch kind {
        case .theme:
            let uri = urlFrom(dictionary, withKey: RangeKeys.uri)
            return ActivityRange(kind: .theme, range: range, url: uri)
        case .post:
            guard let postRange = createPostRange(with: dictionary, and: range) else {
                fallthrough
            }
            return postRange
        case .plugin:
            guard let pluginRange = createPluginRange(with: dictionary, and: range) else {
                fallthrough
            }
            return pluginRange
        default:
            return ActivityRange(kind: kind, range: range, url: url)
        }
    }

    private static func createPostRange(with dictionary: [String: AnyObject], and range: NSRange) -> ActivityPostRange? {
        guard let postID = dictionary[RangeKeys.id] as? Int,
            let siteId = dictionary[RangeKeys.siteId] as? Int else {
                return nil
        }
        return ActivityPostRange(range: range, siteID: siteId, postID: postID)
    }

    private static func createPluginRange(with dictionary: [String : AnyObject], and range: NSRange) -> ActivityPluginRange? {
        guard let siteSlug = dictionary[RangeKeys.siteSlug] as? String,
            let pluginSlug = dictionary[RangeKeys.slug] as? String else {
                return nil
        }
        return ActivityPluginRange(range: range, pluginSlug: pluginSlug, siteSlug: siteSlug)
    }

    private static func urlFrom(_ dictionary: [String: AnyObject], withKey key: String) -> URL? {
        let urlString = dictionary[key] as? String
        return URL(string: urlString ?? "")
    }
}

private enum RangeKeys {
    static let url = "url"
    static let uri = "uri"
    static let id = "id"
    static let siteId = "site_id"
    static let slug = "slug"
    static let siteSlug = "site_slug"
}
