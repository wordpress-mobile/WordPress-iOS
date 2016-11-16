import Foundation

let photonImageQualityMax: UInt = 100
let photonImageQualityDefault: UInt = 80
let photonImageQualityMin: UInt = 1

/// Helper class to create a WordPress URL for various download needs, like specifying image size or using Photon.
public class WPImageURLHelper: NSObject
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

extension WPImageURLHelper
{
    // MARK: Blavatar URLs

    public class func blavatarURL(forHost host: String, size: NSInteger) -> NSURL? {
        let urlString = String(format: "%@/%@?d=404&s=%d", WPBlavatarBaseURL, host.md5(), size)
        return NSURL(string: urlString)
    }

    public class func blavatarURL(forBlavatarURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else { return nil }
        components.query = String(format: "d=404&s=%d", size)
        return components.URL
    }
}

extension NSString
{
    // MARK: Blavatar URLs

    func isBlavatarURL() -> Bool {
        return self.containsString("gravatar.com/blavatar")
    }
}

extension WPImageURLHelper
{
    private struct GravatarDefaults {
        static let scheme = "https"
        static let host = "secure.gravatar.com"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    // MARK: Gravatar URLs

    /**
     Returns the Gravatar URL, for a given email, with the specified size + rating.

     - Parameters:
         - email: the user's email
         - size: required download size
         - rating: image rating filtering

     - Returns: Gravatar's URL
     */
    public class func gravatarURL(forEmail email: String, size: NSInteger, rating: String) -> NSURL? {
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=%@", WPGravatarBaseURL, email.md5(), size, rating)
        return NSURL(string: targetURL)
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
    // MARK: Gravatar URLs

    func isGravatarURL() -> Bool {
        guard let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host
            where host.hasSuffix(".gravatar.com") else {
                return false
        }

        guard let path = self.path
            where path.hasPrefix("/avatar/") else {
                return false
        }

        return true
    }
}

extension WPImageURLHelper
{
    // MARK: Site icon URLs

    public class func siteIconURL(forSiteIconURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else { return nil }
        components.query = String(format: "w=%d&h=%d", size, size)
        return components.URL
    }

    public class func siteIconURL(forContentProvider contentProvider: ReaderPostContentProvider, size: Int) -> NSURL? {
        if (contentProvider.siteIconURL() == nil || contentProvider.siteIconURL().characters.count == 0) {
            guard let blogURL = contentProvider.blogURL(), let hash = NSURL(string: blogURL)?.host?.md5() else {
                return nil
            }

            return NSURL(string: String(format: "https://secure.gravatar.com/blavatar/%@/?s=%d&d=404", hash, size))
        }

        if contentProvider.siteIconURL().containsString("/blavatar/") {
            return NSURL(string: contentProvider.siteIconURL())
        }

        return NSURL(string: String(format: "%@?s=%d&d=404", contentProvider.siteIconURL()))
    }
}

extension WPImageURLHelper
{
    // MARK: Photon URLs

    private static var photonRegex: NSRegularExpression? {
        get {
            do {
                return try NSRegularExpression(pattern: "i\\d+\\.wp\\.com", options: .CaseInsensitive)
            } catch {
                // TODO: handle error
                return nil
            }
        }
    }
    private static let acceptedImageTypes = ["gif", "jpg", "jpeg", "png"]
    private static let useSSLParameter = "ssl=1"

    /**
     Create a "photonized" URL from the passed arguments. Kept as a convenient way to use default values for `forceResize` and `imageQuality` parameters from ObjC.

     - parameters:
        - size: The desired size of the photon image. If height is set to zero the returned image will have a height proportional to the requested width.
        - url: The URL to the source image.

     - returns: A URL to the photon service with the source image as its subject.
     */
    public static func photonDefaultURL(withSize size: CGSize, forImageURL url: NSURL) -> NSURL? {
        return photonURL(withSize: size, forImageURL: url, forceResize: true, imageQuality: photonImageQualityDefault)
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
    public static func photonURL(withSize size: CGSize, forImageURL url: NSURL, forceResize: Bool = true, imageQuality: UInt = photonImageQualityDefault) -> NSURL? {

        guard let urlString = url.absoluteString else {
            return url
        }
        let mutableURLString = NSMutableString(string: urlString)

        // Photon will fail if the URL doesn't end in one of the accepted extensions
        guard let pathExtension = url.pathExtension where acceptedImageTypes.contains(pathExtension) else {
            if url.scheme == nil {
                return NSURL(string: String(format: "http://%@", mutableURLString))
            }
            return url
        }

        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale))
        let boundedQuality = min(max(imageQuality, photonImageQualityMin), photonImageQualityMax)

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
        let queryString = photonQueryString(forSize: scaledSize, usingSSL: url.scheme == "https", forceResize: forceResize, quality: boundedQuality)
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
    // MARK: Photon URLs

    // Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    func isPhotonURL() -> Bool {
        return self.containsString(".wp.com")
    }
}
