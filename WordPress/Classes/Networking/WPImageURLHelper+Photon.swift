//
//  WPImageURLHelper+Photon.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//  Copyright © 2016 WordPress. All rights reserved.
//

import Foundation

extension WPImageURLHelper
{
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
                components.scheme = RequestScheme.Insecure.rawValue
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
        let queryString = photonQueryString(forSize: scaledSize, usingSSL: url.scheme == RequestScheme.Secure.rawValue, forceResize: forceResize, quality: boundedQuality)
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
