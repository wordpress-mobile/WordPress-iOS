import Foundation

/// Helper class to create a WordPress URL for various download needs, like specifying image size or using Photon.
public class WPImageURLHelper: NSObject
{
    struct GravatarDefaults {
        static let scheme = RequestScheme.Secure.rawValue
        static let host = "secure.\(gravatarURLBase)"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    enum RequestScheme: String {
        case Insecure = "http"
        case Secure = "https"
    }

    enum URLComponent: String {
        case Blavatar = "blavatar"
        case Gravatar = "avatar"
    }

    enum ImageURLQueryField: String {
        case Width = "w"
        case Height = "h"
        case Size = "s"
        case Default = "d"
        case ForceDefault = "f"
        case Rating = "r"
    }

    enum ImageDefaultValue: String {
        case None = "404"
        case MysteryMan = "mm"
        case Identicon = "identicon"
        case MonsterID = "monsterid"
        case Wavatar = "wavatar"
        case Retro = "retro"
        case Blank = "blank"
    }

    enum ImageRatingValue: String {
        case G = "g"
        case PG = "pg"
        case R = "r"
        case X = "x"
    }

    static let gravatarURLBase = "gravatar.com"
    static let wordpressURLBase = "wp.com"
}

// MARK: General URLs

extension WPImageURLHelper
{

    /// Adds to the provided url width and height parameters to allow the image to be resized on the server
    ///
    /// - parameter size: the required size for the image
    /// - parameter url:  the original url for the image
    ///
    /// - returns: an URL with the added query parameters.
    ///
    /// - note: If there is any problem with the original URL parsing, the original URL is returned with no changes.
    public class func imageURLWithSize(size: CGSize, forImageURL url:NSURL) -> NSURL {
        guard let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        var newQueryItems = [NSURLQueryItem]()
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                if queryItem.name != ImageURLQueryField.Width.rawValue && queryItem.name != ImageURLQueryField.Height.rawValue {
                    newQueryItems.append(queryItem)
                }
            }
        }
        let height = Int(size.height)
        let width = Int(size.width)
        if height != 0 {
            let heightItem = NSURLQueryItem(name:ImageURLQueryField.Height.rawValue, value:"\(height)")
            newQueryItems.append(heightItem)
        }

        if width != 0 {
            let widthItem = NSURLQueryItem(name:ImageURLQueryField.Width.rawValue, value:"\(width)")
            newQueryItems.append(widthItem)
        }

        urlComponents.queryItems = newQueryItems
        guard let resultURL = urlComponents.URL else {
            return url
        }
        return resultURL
    }
}
