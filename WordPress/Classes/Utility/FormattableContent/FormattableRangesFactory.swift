
protocol FormattableRangesFactory {
    static func contentRange(from dictionary: [String: AnyObject]) -> FormattableContentRange?
}

extension FormattableRangesFactory {
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
