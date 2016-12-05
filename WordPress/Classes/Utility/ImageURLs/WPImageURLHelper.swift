import Foundation

/// Helper class to create a WordPress URL for various download needs, like specifying image size or using Photon.
public class WPImageURLHelper: NSObject
{
    struct GravatarDefaults {
        static let scheme = RequestScheme.Secure
        static let host = "secure.\(gravatarURLBase)"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    struct RequestScheme {
        static let Insecure = "http"
        static let Secure = "https"
    }

    struct URLComponent {
        static let Blavatar = "blavatar"
        static let Gravatar = "avatar"
    }

    struct ImageURLQueryField {
        static let Width = "w"
        static let Height = "h"
        static let Size = "s"
        static let Default = "d"
        static let ForceDefault = "f"
        static let Rating = "r"
    }

    struct ImageDefaultValue {
        static let None = "404"
        static let MysteryMan = "mm"
        static let Identicon = "identicon"
        static let MonsterID = "monsterid"
        static let Wavatar = "wavatar"
        static let Retro = "retro"
        static let Blank = "blank"
    }

    struct ImageRatingValue {
        static let G = "g"
        static let PG = "pg"
        static let R = "r"
        static let X = "x"
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
                if queryItem.name != ImageURLQueryField.Width && queryItem.name != ImageURLQueryField.Height {
                    newQueryItems.append(queryItem)
                }
            }
        }
        let height = Int(size.height)
        let width = Int(size.width)
        if height != 0 {
            let heightItem = NSURLQueryItem(name:ImageURLQueryField.Height, value:"\(height)")
            newQueryItems.append(heightItem)
        }

        if width != 0 {
            let widthItem = NSURLQueryItem(name:ImageURLQueryField.Width, value:"\(width)")
            newQueryItems.append(widthItem)
        }

        urlComponents.queryItems = newQueryItems
        guard let resultURL = urlComponents.URL else {
            return url
        }
        return resultURL
    }
}
