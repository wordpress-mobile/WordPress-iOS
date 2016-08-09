import Foundation


// MARK: - NotificationMedia Entity
//
class NotificationMedia
{
    ///
    ///
    let kind: Kind

    ///
    ///
    let mediaURL: NSURL?

    ///
    ///
    let size: CGSize?

    ///
    ///
    let range: NSRange?


    ///
    ///
    enum Kind: String {
        case Image = "image"
        case Badge = "badge"
    }


    ///
    ///
    init(dictionary: [String: AnyObject]) {

        let type = dictionary[Keys.RawType] as? String ?? String()
        kind = Kind(rawValue: type) ?? .Image

        if let indices = dictionary[Keys.Indices] as? [Int],
            let start = indices.first, let end = indices.last
        {
            let length = start - end
            range = NSMakeRange(start, length)
        }

        if let url = dictionary[Keys.URL] as? String {
            mediaURL = NSURL(string: url)
        }

        if let width = dictionary[Keys.Width] as? NSNumber,
            let height = dictionary[Keys.Height] as? NSNumber
        {
            size = CGSize(width: width.integerValue, height: height.integerValue)
        }
    }

    ///
    ///
    class func mediaFromArray(media: [AnyObject]?) -> [NotificationMedia] {
        let media = media ?? []
        return media.flatMap {
            guard let dictionary = $0 as? [String: AnyObject] else {
                return nil
            }

            return NotificationMedia(dictionary: dictionary)
        }
    }


    // MARK: - Private Helpers

    /// Parsing Keys
    ///
    private enum Keys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Width        = "width"
        static let Height       = "height"
    }
}
