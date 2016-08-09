import Foundation



// MARK: - NotificationRange Entity
//
class NotificationRange
{
    /// Kind of the current Range
    ///
    let kind: Kind

    /// Text Range Associated!
    ///
    let range: NSRange

    /// Resource URL, if any.
    ///
    private(set) var url: NSURL?

    /// Comment ID, if any.
    ///
    private(set) var commentID: NSNumber?

    /// Post ID, if any.
    ///
    private(set) var postID: NSNumber?

    /// Site ID, if any.
    ///
    private(set) var siteID: NSNumber?

    /// User ID, if any.
    ///
    private(set) var userID: NSNumber?

    /// String Payload, if any.
    ///
    private(set) var value: String?


    /// Designated Initializer
    ///
    init?(dictionary: [String: AnyObject]) {
        guard let type = dictionary[Keys.RawType] as? String,
            let indices = dictionary[Keys.Indices] as? [Int],
            let start = indices.first, let end = indices.last else
        {
            return nil
        }

        kind = Kind(rawValue: type) ?? .Site
        range = NSMakeRange(start, end - start)


        if let rawURL = dictionary[Keys.URL] as? String {
            url = NSURL(string: rawURL)
        }


        //  SORRY: << Let me stress this. Sorry, i'm 1000% against Duck Typing.
        //  ======
        //  `id` is coupled with the `type`. Which, in turn, is also duck typed.
        //
        //      type = comment  => id = comment_id
        //      type = user     => id = user_id
        //      type = post     => id = post_id
        //      type = site     => id = site_id
        //
        switch kind {
        case .Comment:
            commentID = dictionary[Keys.Id] as? NSNumber
            postID = dictionary[Keys.PostId] as? NSNumber
        case .Noticon:
            value = dictionary[Keys.Value] as? String
        case .Post:
            postID = dictionary[Keys.Id] as? NSNumber
        case .Site:
            siteID = dictionary[Keys.Id] as? NSNumber
        case .User:
            userID = dictionary[Keys.Id] as? NSNumber
        default:
// TODO: Should always run?
            siteID = dictionary[Keys.SiteId] as? NSNumber
        }
    }
}


// MARK: - NotificationRange Parsers
//
extension NotificationRange
{
    /// Given a NotificationBlock Dictionary, will parse all of the NotificationRange associated entities.
    ///
    class func rangesFromBlockDictionary(dictionary: [String: AnyObject]) -> [NotificationRange] {
        guard let ranges = dictionary[Keys.BlockRanges] as? [[String: AnyObject]] else {
            return []
        }

        return ranges.flatMap {
            return NotificationRange(dictionary: $0)
        }
    }
}


// MARK: - NotificationRange Types
//
extension NotificationRange
{
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
    private enum Keys {
        static let BlockRanges  = "ranges"
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Id           = "id"
        static let Value        = "value"
        static let SiteId       = "site_id"
        static let PostId       = "post_id"
    }
}
