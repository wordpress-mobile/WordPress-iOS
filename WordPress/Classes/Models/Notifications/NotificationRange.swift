import Foundation


// MARK: - NotificationRange Entity
//
class NotificationRange
{
    ///
    ///
    let kind: Kind

    ///
    ///
    let range: NSRange

    ///
    ///
    private(set) var value: String?

    ///
    ///
    private(set) var url: NSURL?

    ///
    ///
    private(set) var postID: NSNumber?

    ///
    ///
    private(set) var commentID: NSNumber?

    ///
    ///
    private(set) var userID: NSNumber?

    ///
    ///
    private(set) var siteID: NSNumber?

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
    init(dictionary: [String: AnyObject]) {
        if let indices = dictionary[Keys.Indices] as? [Int],
            let start = indices.first, let end = indices.last
        {
            let length = start - end
            range = NSMakeRange(start, length)
        }

        let type = dictionary[Keys.RawType] as? String ?? String()
        kind = Kind(rawValue: type) ?? .Site

        if let rawURL = dictionary[Keys.URL] as? String {
            url = NSURL(string: rawURL)
        }


        //  SORRY: << Let me stress this. Sorry, i'm 1000% against Duck Typing.
        //  ======
        //  `id` is coupled with the `type`. Which, in turn, is also duck typed.
        //
        //      type = post     => id = post_id
        //      type = comment  => id = comment_id
        //      type = user     => id = user_id
        //      type = site     => id = site_id
        //
        switch kind {
        case .User:
            userID = dictionary[Keys.Id] as? NSNumber
        case .Post:
            postID = dictionary[Keys.Id] as? NSNumber
        case .Comment:
            commentID = dictionary[Keys.Id] as? NSNumber
            postID = dictionary[Keys.PostId] as? NSNumber
        case .Noticon:
            value = dictionary[Keys.Value] as? String
        case .Site:
            siteID = dictionary[Keys.Id] as? NSNumber
        default:
            siteID = dictionary[Keys.SiteId] as? NSNumber
        }
    }


    ///
    ///
    class func rangesFromArray(ranges: [AnyObject]?) -> [NotificationRange] {
        let ranges = ranges ?? []
        return ranges.flatMap {
            guard let dictionary = $0 as? [String: AnyObject] else {
                return nil
            }

            return NotificationRange(dictionary: dictionary)
        }
    }


    // MARK: - Private Helpers

    /// Parsing Keys
    ///
    private enum Keys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Id           = "id"
        static let Value        = "value"
        static let SiteId       = "site_id"
        static let PostId       = "post_id"
    }
}
