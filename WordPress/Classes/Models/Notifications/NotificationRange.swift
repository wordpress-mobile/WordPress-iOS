import Foundation



// MARK: - NotificationRange Entity
//
class NotificationRange {
    /// Kind of the current Range
    ///
    let kind: Kind

    /// Text Range Associated!
    ///
    let range: NSRange

    /// Resource URL, if any.
    ///
    fileprivate(set) var url: URL?

    /// Comment ID, if any.
    ///
    fileprivate(set) var commentID: NSNumber?

    /// Post ID, if any.
    ///
    fileprivate(set) var postID: NSNumber?

    /// Site ID, if any.
    ///
    fileprivate(set) var siteID: NSNumber?

    /// User ID, if any.
    ///
    fileprivate(set) var userID: NSNumber?

    /// String Payload, if any.
    ///
    fileprivate(set) var value: String?


    /// Designated Initializer
    ///
    init?(dictionary: [String: AnyObject]) {
        guard let type = dictionary[RangeKeys.RawType] as? String, let indices = dictionary[RangeKeys.Indices] as? [Int],
            let start = indices.first, let end = indices.last else {
            return nil
        }

        kind = Kind(rawValue: type) ?? .Site
        range = NSMakeRange(start, end - start)
        siteID = dictionary[RangeKeys.SiteId] as? NSNumber

        if let rawURL = dictionary[RangeKeys.URL] as? String {
            url = URL(string: rawURL)
        }

        //  SORRY: << Let me stress this. Sorry, i'm 1000% against Duck Typing.
        //  ======
        //  `id` is coupled with the `kind`. Which, in turn, is also duck typed.
        //
        //      type = comment  => id = comment_id
        //      type = user     => id = user_id
        //      type = post     => id = post_id
        //      type = site     => id = site_id
        //
        switch kind {
        case .Comment:
            commentID = dictionary[RangeKeys.Id] as? NSNumber
            postID = dictionary[RangeKeys.PostId] as? NSNumber
        case .Noticon:
            value = dictionary[RangeKeys.Value] as? String
        case .Post:
            postID = dictionary[RangeKeys.Id] as? NSNumber
        case .Site:
            siteID = dictionary[RangeKeys.Id] as? NSNumber
        case .User:
            userID = dictionary[RangeKeys.Id] as? NSNumber
        default:
            break
        }
    }
}


// MARK: - NotificationRange Parsers
//
extension NotificationRange {
    /// Parses NotificationRange instances, given an array of raw ranges.
    ///
    class func rangesFromArray(_ ranges: [[String: AnyObject]]?) -> [NotificationRange] {
        let parsed = ranges?.flatMap {
            return NotificationRange(dictionary: $0)
        }

        return parsed ?? []
    }
}


// MARK: - NotificationRange Types
//
extension NotificationRange {
    /// Known kinds of Range
    ///
    enum Kind: String {
        case User               = "user"
        case Post               = "post"
        case Comment            = "comment"
        case Stats              = "stat"
        case Follow             = "follow"
        case Blockquote         = "blockquote"
        case Noticon            = "noticon"
        case Site               = "site"
        case Match              = "match"
    }

    /// Parsing Keys
    ///
    fileprivate enum RangeKeys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Id           = "id"
        static let Value        = "value"
        static let SiteId       = "site_id"
        static let PostId       = "post_id"
    }
}
