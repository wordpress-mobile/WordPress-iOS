import Foundation



// MARK: - FormattableMediaContent Entity
//
public class FormattableMediaItem {
    /// Kind of the current Media.
    ///
    public let kind: Kind

    /// Text Range Associated!
    ///
    public let range: NSRange

    /// Resource URL, if any.
    ///
    public private(set) var mediaURL: URL?

    /// Resource Size, if any.
    ///
    public private(set) var size: CGSize?


    /// Designated Initializer.
    ///
    init?(dictionary: [String: AnyObject]) {
        guard let type = dictionary[MediaKeys.RawType] as? String, let indices = dictionary[MediaKeys.Indices] as? [Int],
            let start = indices.first, let end = indices.last else {
                return nil
        }

        kind = Kind(rawValue: type) ?? .image
        range = NSMakeRange(start, end - start)

        if let url = dictionary[MediaKeys.URL] as? String {
            mediaURL = URL(string: url)
        }

        if let width = dictionary[MediaKeys.Width] as? NSNumber, let height = dictionary[MediaKeys.Height] as? NSNumber {
            size = CGSize(width: width.intValue, height: height.intValue)
        }
    }
}


// MARK: - NotificationRange Parsers
//
extension FormattableMediaItem {
    /// Parses FormattableMediaContent instances, given an array of raw media.
    ///
    public class func mediaFromArray(_ media: [[String: AnyObject]]?) -> [FormattableMediaItem] {
        let parsed = media?.compactMap {
            return FormattableMediaItem(dictionary: $0)
        }

        return parsed ?? []
    }
}


// MARK: - FormattableMediaContent Types
//
public extension FormattableMediaItem {
    /// Known kinds of Media Entities
    ///
    public enum Kind: String {
        case image              = "image"
        case badge              = "badge"
    }

    /// Parsing Keys
    ///
    fileprivate enum MediaKeys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Width        = "width"
        static let Height       = "height"
    }
}
