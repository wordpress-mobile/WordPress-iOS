import Foundation

private enum URLComponent: String {
    case Blavatar = "blavatar"
    case Gravatar = "avatar"
}

private let gravatarURLBase = "gravatar.com"

private let insecureScheme = "http"
private let secureScheme = "https"

/// Helper class to create a WordPress URL for various download needs, like specifying image size or using Photon.
public class WPImageURLHelper: NSObject
{

    static let defaultBlavatarSize: CGFloat = 40

    private struct GravatarDefaults {
        static let scheme = secureScheme
        static let host = "secure.\(gravatarURLBase)"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    private static var photonRegex: NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: "i\\d+\\.wp\\.com", options: .CaseInsensitive)
        } catch {
            // TODO: handle error
            return nil
        }
    }
    private static let acceptedImageTypes = ["gif", "jpg", "jpeg", "png"]
    private static let useSSLParameter = "ssl=1"

    private enum PhotonImageQuality: UInt {
        case Max = 100
        case Default = 80
        case Min = 1
    }
}

// MARK: General URLs

extension WPImageURLHelper
{
    /**
     Adds to the provided url width and height parameters to allow the image to be resized on the server

     - parameter size: the required size for the image
     - parameter url:  the original url for the image

     - returns: an URL with the added query parameters.

     - note: If there is any problem with the original URL parsing, the original URL is returned with no changes.
     */
    public class func imageURLWithSize(size: CGSize, forImageURL url:NSURL) -> NSURL {
        guard let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        var newQueryItems = [NSURLQueryItem]()
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                if queryItem.name != "w" && queryItem.name != "h" {
                    newQueryItems.append(queryItem)
                }
            }
        }
        let height = Int(size.height)
        let width = Int(size.width)
        if height != 0 {
            let heightItem = NSURLQueryItem(name:"h", value:"\(height)")
            newQueryItems.append(heightItem)
        }

        if width != 0 {
            let widthItem = NSURLQueryItem(name:"w", value:"\(width)")
            newQueryItems.append(widthItem)
        }

        urlComponents.queryItems = newQueryItems
        guard let resultURL = urlComponents.URL else {
            return url
        }
        return resultURL
    }
}

// MARK: {Gr|Bl}avatar URLs

extension WPImageURLHelper
{
    public class func avatarURL(withHash hash: String, type: WPAvatarSourceType, size: CGSize) -> NSURL? {
        var subPath: String? = nil
        switch type {
        case .Blavatar:
            subPath = URLComponent.Blavatar.rawValue
            break
        case .Gravatar:
            subPath = URLComponent.Gravatar.rawValue
            break
        case .Unknown:
            break
        }

        var path = gravatarURLBase
        if subPath != nil {
            path = (path as NSString).stringByAppendingPathComponent(subPath!)
        }
        path = (path as NSString).stringByAppendingPathComponent(hash)

        let components = NSURLComponents()
        components.scheme = insecureScheme
        components.path = path
        components.queryItems = [
            NSURLQueryItem(name: "d", value: "identicon"),
            NSURLQueryItem(name: "s", value: "\(Int(size.width * UIScreen.mainScreen().scale))")
        ]
        return components.URL
    }
}

// MARK: Blavatar URLs

extension WPImageURLHelper
{
    public class func blavatarURL(forHost host: String, size: NSInteger) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(host.md5())
        let components = NSURLComponents(string: path)
        components?.queryItems = [
            NSURLQueryItem(name: "d", value: "404"),
            NSURLQueryItem(name: "s", value: "\(size)")
        ]
        return components?.URL
    }

    public class func blavatarURL(forBlavatarURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else { return nil }
        components.queryItems = [
            NSURLQueryItem(name: "d", value: "404"),
            NSURLQueryItem(name: "s", value: "\(size)")
        ]
        return components.URL
    }
}

extension NSString
{
    func isBlavatarURL() -> Bool {
        return self.containsString("\(gravatarURLBase)/\(URLComponent.Blavatar.rawValue)")
    }
}

// MARK: Gravatar URLs

extension WPImageURLHelper
{
    /**
     Returns the Gravatar URL, for a given email, with the specified size + rating.

     - Parameters:
         - email: the user's email
         - size: required download size
         - rating: image rating filtering

     - Returns: Gravatar's URL
     */
    public class func gravatarURL(forEmail email: String, size: NSInteger, rating: String) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(email.md5())
        let components = NSURLComponents(string: path)
        components?.queryItems = [
            NSURLQueryItem(name: "d", value: "404"),
            NSURLQueryItem(name: "s", value: "\(size)"),
            NSURLQueryItem(name: "r", value: "\(rating)")
        ]
        return components?.URL
    }

    public class func gravatarURL(forURL url: NSURL) -> NSURL? {
        guard url.isGravatarURL() else {
            return nil
        }

        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.scheme = GravatarDefaults.scheme
        components.host = GravatarDefaults.host
        components.query = nil

        // Treat unknown@gravatar.com as a nil url
        guard let hash = url.lastPathComponent
            where hash != GravatarDefaults.unknownHash else {
                return nil
        }

        guard let sanitizedURL = components.URL else {
            return nil
        }

        return sanitizedURL
    }
}

extension NSURL
{
    func isGravatarURL() -> Bool {
        guard let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host
            where host.hasSuffix(".\(gravatarURLBase)") else {
                return false
        }

        guard let path = self.path
            where path.hasPrefix("/\(URLComponent.Gravatar.rawValue)/") else {
                return false
        }

        return true
    }
}

// MARK: Site icon URLs

extension WPImageURLHelper
{
    public class func siteIconURL(forSiteIconURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else { return nil }
        components.queryItems = [
            NSURLQueryItem(name: "h", value: "\(size)"),
            NSURLQueryItem(name: "w", value: "\(size)")
        ]
        return components.URL
    }

    public class func siteIconURL(forContentProvider contentProvider: ReaderPostContentProvider, size: Int) -> NSURL? {
        if (contentProvider.siteIconURL() == nil || contentProvider.siteIconURL().characters.count == 0) {
            guard let blogURL = contentProvider.blogURL(), let hash = NSURL(string: blogURL)?.host?.md5() else {
                return nil
            }

            var path = GravatarDefaults.host
            path = (path as NSString).stringByAppendingPathComponent(URLComponent.Blavatar.rawValue)
            path = (path as NSString).stringByAppendingPathComponent(hash)

            let components = NSURLComponents()
            components.scheme = GravatarDefaults.scheme
            components.path = path
            components.queryItems = [
                NSURLQueryItem(name: "d", value: "404"),
                NSURLQueryItem(name: "s", value: "\(size)")
            ]
            return components.URL
        }

        if !contentProvider.siteIconURL().containsString("/\(URLComponent.Blavatar.rawValue)/") {
            return NSURL(string: contentProvider.siteIconURL())
        }

        let components = NSURLComponents(string: contentProvider.siteIconURL())
        components?.queryItems = [
            NSURLQueryItem(name: "d", value: "404"),
            NSURLQueryItem(name: "s", value: "\(size)")
        ]
        return components?.URL
    }

    public class func siteIconURL(forPath path: String?, imageViewBounds bounds: CGRect?) -> NSURL? {
        guard
            let path = path,
            let bounds = bounds,
            let url = NSURL(string: path),
            let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
            else { return nil }

        let size = blavatarSizeInPoints(forImageViewBounds: bounds)
        components.queryItems = [
            NSURLQueryItem(name: "d", value: "404"),
            NSURLQueryItem(name: "s", value: "\(size)")
        ]

        return components.URL
    }

    public static func blavatarSizeInPoints(forImageViewBounds bounds: CGRect) -> Int {
        var size = defaultBlavatarSize

        if !CGSizeEqualToSize(bounds.size, .zero) {
            size = max(bounds.width, bounds.height)
        }

        return Int(size * UIScreen.mainScreen().scale)
    }
}

// MARK: Photon URLs

extension WPImageURLHelper
{
    /**
     Create a "photonized" URL from the passed arguments. Kept as a convenient way to use default values for `forceResize` and `imageQuality` parameters from ObjC.

     - parameters:
        - size: The desired size of the photon image. If height is set to zero the returned image will have a height proportional to the requested width.
        - url: The URL to the source image.

     - returns: A URL to the photon service with the source image as its subject.
     */
    public static func photonDefaultURL(withSize size: CGSize, forImageURL url: NSURL) -> NSURL? {
        return photonURL(withSize: size, forImageURL: url, forceResize: true, imageQuality: PhotonImageQuality.Default.rawValue)
    }

    /**
     Create a "photonized" URL from the passed arguments.

     - parameters:
        - size: The desired size of the photon image. If height is set to zero the returned image will have a height proportional to the requested width.
        - url: The URL to the source image.
        - forceResize: By default Photon does not upscale beyond a certain percentage. Setting this to `true` forces the returned image to match the specified size. Default is `true`.
        - quality: An integer value 1 - 100. Passed values are constrained to this range. Default is 80%.

     - returns: A URL to the photon service with the source image as its subject.
     */
    public static func photonURL(withSize size: CGSize, forImageURL url: NSURL, forceResize: Bool = true, imageQuality: UInt = PhotonImageQuality.Default.rawValue) -> NSURL? {

        guard let urlString = url.absoluteString else {
            return url
        }
        let mutableURLString = NSMutableString(string: urlString)

        // Photon will fail if the URL doesn't end in one of the accepted extensions
        guard let pathExtension = url.pathExtension where acceptedImageTypes.contains(pathExtension) else {
            if url.scheme == nil {
                let components = NSURLComponents()
                components.scheme = insecureScheme
                components.path = urlString
                return components.URL
            }
            return url
        }

        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale))
        let boundedQuality = min(max(imageQuality, PhotonImageQuality.Min.rawValue), PhotonImageQuality.Max.rawValue)

        // If the URL is already a Photon URL reject its photon params, and substitute our own.
        if isURLPhotonURL(url) {
            var components = mutableURLString.componentsSeparatedByString("?")
            if components.count == 2 {
                let useSSL = mutableURLString.containsString(useSSLParameter)
                components[1] = self.photonQueryString(forSize: scaledSize, usingSSL: useSSL, forceResize: forceResize, quality: boundedQuality)
                return NSURL(string: components.joinWithSeparator("?"))
            }
            // Saftey net. Don't photon photon!
            return url
        }

        // remove the protocol ("http" or "https") from the working url string
        let protocolRange = mutableURLString.rangeOfString("^https?://", options: .RegularExpressionSearch)
        mutableURLString.deleteCharactersInRange(protocolRange)

        // Photon rejects resizing mshots
        if mutableURLString.containsString("/mshots/") {
            mutableURLString.appendFormat("?w=%i", size.width)
            if scaledSize.height != 0 { // ???: the original only tested for equality to 0. What if height < 0?
                mutableURLString.appendFormat("&h=%i", size.height)
            }
            return NSURL(string: mutableURLString as String)
        }

        // Strip original resizing parameters, or we might get an image too small
        let sizeStrippedURL = mutableURLString.componentsSeparatedByString("?w=").first!
        let queryString = photonQueryString(forSize: scaledSize, usingSSL: url.scheme == secureScheme, forceResize: forceResize, quality: boundedQuality)
        return NSURL(string: String(format: "https://i0.wp.com/%@?%@", sizeStrippedURL, queryString))
    }

    private static func photonQueryString(forSize size: CGSize, usingSSL useSSL: Bool, forceResize: Bool, quality: UInt) -> String {
        var queryString: NSMutableString
        if size.height == 0 {
            queryString = NSMutableString(format: "w=%i", size.width)
        } else {
            let method = forceResize ? "resize" : "fit"
            queryString = NSMutableString(format: "%@=%.0f,%.0f", method, size.width, size.height)
        }

        if useSSL {
            queryString.appendFormat("&%@", useSSLParameter)
        }

        return String(format: "quality=%d&%@", quality, queryString)
    }

    private static func isURLPhotonURL(url: NSURL) -> Bool {
        guard let host = url.host else {
            return false
        }

        return photonRegex?.numberOfMatchesInString(host, options: NSMatchingOptions(rawValue: UInt(0)), range: NSRange(location: 0, length: host.characters.count)) > 0
    }

}

extension NSString
{
    // Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    func isPhotonURL() -> Bool {
        return self.containsString(".wp.com")
    }
}
