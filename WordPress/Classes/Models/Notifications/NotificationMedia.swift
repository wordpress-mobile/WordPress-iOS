import Foundation



// MARK: - NotificationMedia Entity
//
class NotificationMedia
{
    ///
    ///
    enum Kind: String {
        case Image = "image"
        case Badge = "badge"
    }

    ///
    ///
    let kind: Kind

    ///
    ///
    let range: NSRange

    ///
    ///
    private(set) var mediaURL: NSURL?

    ///
    ///
    private(set) var size: CGSize?

    ///
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

    /// Parses an array of NotificationMedia Definitions into NotificationMedia Instances
    ///
    class func mediaFromArray(media: [[String: AnyObject]]?) -> [NotificationMedia]? {
        return media?.flatMap {
            return NotificationMedia(dictionary: $0)
        }
    }
}


// MARK: - NotificationMedia Constants
//
private extension NotificationMedia
{
    enum Keys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Width        = "width"
        static let Height       = "height"
    }
}
