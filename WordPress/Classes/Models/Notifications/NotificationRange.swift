import Foundation



// MARK: - NotificationRange Entity
//
class NotificationRange
{
    ///
    ///
    enum Kind: String {
        case User       = "user"
        case Post       = "post"
        case Comment    = "comment"
        case Stats      = "stat"
        case Follow     = "follow"
        case Blockquote = "blockquote"
        case Noticon    = "noticon"
        case Site       = "site"
        case Match      = "match"
    }

    ///
    ///
    let kind: Kind

    ///
    ///
    let range: NSRange

    ///
    ///
    private(set) var url: NSURL?

    ///
    ///
    private(set) var commentID: NSNumber?

    ///
    ///
    private(set) var postID: NSNumber?

    ///
    ///
    private(set) var siteID: NSNumber?

    ///
    ///
    private(set) var userID: NSNumber?
    ///
    ///
    private(set) var value: String?

    ///
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
            siteID = dictionary[Keys.SiteId] as? NSNumber
        }
    }


    /// Parses an array of NotificationRange Definitions into NotificationRange Instances
    ///
    class func rangesFromArray(ranges: [[String: AnyObject]]?) -> [NotificationRange]? {
        return ranges?.flatMap {
            return NotificationRange(dictionary: $0)
        }
    }
}


// MARK: - NotificationRange Constants
//
private extension NotificationRange
{
    enum Keys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Id           = "id"
        static let Value        = "value"
        static let SiteId       = "site_id"
        static let PostId       = "post_id"
    }
}
