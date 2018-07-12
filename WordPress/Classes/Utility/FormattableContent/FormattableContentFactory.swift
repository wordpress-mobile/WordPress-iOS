
protocol FormattableContentFactory {
    static func content(from blocks: [[String: AnyObject]],
                        actionsParser parser: FormattableContentActionParser,
                        parent: FormattableContentParent) -> [FormattableContent]
}

struct ActivityFormattableContentFactory: FormattableContentFactory {
    public static func content(from blocks: [[String: AnyObject]],
                               actionsParser parser: FormattableContentActionParser,
                               parent: FormattableContentParent) -> [FormattableContent] {

        return blocks.compactMap {
            let actions = parser.parse($0[Constants.ActionsKey] as? [String: AnyObject])
            let ranges = rangesFrom(disctionary: $0)
            return FormattableTextContent(dictionary: $0, actions: actions, ranges: ranges, parent: parent)
        }
    }

    static func rangesFrom(disctionary: [String: AnyObject]) -> [FormattableContentRange] {
        let rawRanges   = disctionary[Constants.Ranges] as? [[String: AnyObject]]
        let parsed = rawRanges?.compactMap(ActivityRangesFactory.contentRange)
        return parsed ?? []
    }
}

private enum Constants {
    static let ActionsKey = "actions"
    static let Ranges       = "ranges"
}

private enum RangeKeys {
    static let rawType = "type"
    static let url = "url"
    static let uri = "uri"
    static let indices = "indices"
    static let id = "id"
    static let value = "value"
    static let siteId = "site_id"
    static let postId = "post_id"
    static let slug = "slug"
    static let siteSlug = "site_slug"
}

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
