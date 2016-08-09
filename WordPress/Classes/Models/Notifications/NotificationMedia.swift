import Foundation



// MARK: - NotificationMedia Entity
//
class NotificationMedia
{
    /// Kind of the current Media.
    ///
    let kind: Kind

    /// Text Range Associated!
    ///
    let range: NSRange

    /// Resource URL, if any.
    ///
    private(set) var mediaURL: NSURL?

    /// Resource Size, if any.
    ///
    private(set) var size: CGSize?


    /// Designated Initializer.
    ///
    init?(dictionary: [String: AnyObject]) {
        guard let type = dictionary[Keys.RawType] as? String,
            let indices = dictionary[Keys.Indices] as? [Int],
            let start = indices.first, let end = indices.last else
        {
            return nil
        }

        kind = Kind(rawValue: type) ?? .Image
        range = NSMakeRange(start, end - start)

        if let url = dictionary[Keys.URL] as? String {
            mediaURL = NSURL(string: url)
        }

        if let width = dictionary[Keys.Width] as? NSNumber,
            let height = dictionary[Keys.Height] as? NSNumber
        {
            size = CGSize(width: width.integerValue, height: height.integerValue)
        }
    }
}


// MARK: - NotificationRange Parsers
//
extension NotificationMedia
{
    /// Given a NotificationBlock Dictionary, will parse all of the NotificationMedia associated entities.
    ///
    class func mediaFromBlockDictionary(dictionary: [String: AnyObject]) -> [NotificationMedia] {
        guard let media = dictionary[Keys.BlockMedia] as? [[String: AnyObject]] else {
            return []
        }

        return media.flatMap {
            return NotificationMedia(dictionary: $0)
        }
    }
}


// MARK: - NotificationMedia Types
//
extension NotificationMedia
{
    /// Known kinds of Media Entities
    ///
    enum Kind: String {
        case Image              = "image"
        case Badge              = "badge"
    }

    /// Parsing Keys
    ///
    private enum Keys {
        static let BlockMedia   = "media"
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Width        = "width"
        static let Height       = "height"
    }
}
