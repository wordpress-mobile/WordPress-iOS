
public protocol FormattableContentFactory {
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
        switch rangeKind {
        case .post:
            guard let postID = dictionary[RangeKeys.id] as? Int, let siteId = dictionary[RangeKeys.siteId] as? Int else {
                fallthrough
            }
            return ActivityPostRange(range: range, siteID: siteId, postID: postID)
        case .comment:
            return ActivityCommentRange(range: range, url: url)
        case .theme:
            let uri = urlFrom(dictionary, withKey: RangeKeys.uri)
            return ActivityThemeRange(range: range, url: uri)
        default:
            return ActivityRange(range: range, url: url)
        }
    }

    private static func urlFrom(_ dictionary: [String: AnyObject], withKey key: String) -> URL? {
        let urlString = dictionary[key] as? String
        return URL(string: urlString ?? "")
    }
}
