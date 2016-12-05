//
//  WPImageURLHelper+Photon.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//

import Foundation

extension WPImageURLHelper
{
    private static let acceptedImageTypes = ["gif", "jpg", "jpeg", "png"]

    private struct PhotonSubdomain {
        static let Zero = "i0"
        static let One = "i1"
        static let Two = "i2"
    }

    private struct PhotonQueryFields {
        static let SSL = "ssl"
        static let Quality = "quality"
        static let Resize = "resize"
        static let Fit = "fit"
        static let Crop = "crop"
        static let AddLetterbox = "lb"
        static let RemoveLetterBox = "ulb"
        static let Filter = "filter"
        static let Brightness = "brightness"
        static let Contrast = "contrast"
        static let Colorize = "colorize"
        static let Smooth = "smooth"
        static let Zoom = "zoom"
        static let Strip = "strip"
    }

    private enum PhotonFilterValue {
        static let Negate = "negate"
        static let Grayscale = "grayscale"
        static let Sepia = "sepia"
        static let EdgeDetect = "edgedetect"
        static let Emboss = "emboss"
        static let BlurGaussian = "blurgaussian"
        static let BlurSelective = "blurselective"
        static let MeanRemoval = "meanremoval"
    }

    private enum PhotonStipValue {
        static let All = "all"
    }

    private enum PhotonSSLValue {
        static let Enabled = "1"
    }

    private enum PhotonImageQuality {
        static let Max: UInt = 100
        static let Default: UInt = 80
        static let Min: UInt = 1
    }

    /// - returns: `true` for "i0.wp.com", "i1.wp.com" & "i2.wp.com", `false` otherwise (see https://developer.wordpress.com/docs/photon/)
    public static func isPhotonURL(url: NSString) -> Bool {
        return url.containsString(".\(wordpressURLBase)")
    }

    /// Create a "photonized" URL from the passed arguments. Kept as a convenient way to use default values for `forceResize` and `imageQuality` parameters from ObjC.
    ///
    /// - parameters:
    ///     - size: The desired size of the photon image. If height is set to zero the returned image will have a height proportional to the requested width.
    ///     - url: The URL to the source image.
    ///
    /// - returns: A URL to the photon service with the source image as its subject.
    public static func photonDefaultURL(withSize size: CGSize, forImageURL url: NSURL) -> NSURL? {
        return photonURL(withSize: size, forImageURL: url, forceResize: true, imageQuality: PhotonImageQuality.Default)
    }

    /// Create a "photonized" URL from the passed arguments.
    ///
    /// - parameters:
    ///     - size: The desired size of the photon image. If height is set to zero the returned image will have a height proportional to the requested width.
    ///     - url: The URL to the source image.
    ///     - forceResize: By default Photon does not upscale beyond a certain percentage. Setting this to `true` forces the returned image to match the specified size. Default is `true`.
    ///     - quality: An integer value 1 - 100. Passed values are constrained to this range. Default is 80%.
    ///
    /// - returns: A URL to the photon service with the source image as its subject.
    public static func photonURL(withSize size: CGSize, forImageURL url: NSURL, forceResize: Bool = true, imageQuality: UInt = PhotonImageQuality.Default) -> NSURL? {
        guard
            let urlString = url.absoluteString,
            let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true),
            let urlPath = urlComponents.path
        else {
            return url
        }

        // Photon will fail if the URL doesn't end in one of the accepted extensions
        guard let pathExtension = url.pathExtension
            where acceptedImageTypes.contains(pathExtension)
        else {
            if url.scheme == nil {
                let components = NSURLComponents()
                components.scheme = RequestScheme.Insecure
                components.path = urlString
                return components.URL
            }
            return url
        }

        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale))
        let boundedQuality = min(max(imageQuality, PhotonImageQuality.Min), PhotonImageQuality.Max)

        // If the URL is already a Photon URL reject its photon params, and substitute our own.
        if isPhotonURL(urlString) {
            if urlComponents.queryItems != nil {
                return photonURL(withPhotonURLComponents: urlComponents, scaledSize: scaledSize, forceResize: forceResize, quality: boundedQuality)
            }

            // Saftey net. Don't photon photon!
            return url
        }

        // Photon rejects resizing mshots
        if urlPath.containsString("/mshots/") {
            return photonURL(forMshotURLComponents: urlComponents, scaledSize: scaledSize)
        }

        return photonURL(withURLComponents: urlComponents, url: url, scaledSize: scaledSize, forceResize: forceResize, quality: boundedQuality)
    }

    private static func photonURL(withURLComponents urlComponents: NSURLComponents, url: NSURL, scaledSize: CGSize, forceResize: Bool, quality: UInt) -> NSURL? {
        urlComponents.scheme = RequestScheme.Secure

        // the host will become i0.wp.com, and the path will be the original host+path
        if let host = urlComponents.host, let path = urlComponents.path {
            urlComponents.path = ("/\(host)" as NSString).stringByAppendingPathComponent(path)
        }
        urlComponents.host = "\(PhotonSubdomain.Zero).\(wordpressURLBase)"

        // Strip original resizing parameters, or we might get an image too small
        urlComponents.queryItems = photonQueryItems(forSize: scaledSize, usingSSL: url.scheme == RequestScheme.Secure, forceResize: forceResize, quality: quality)

        urlComponents.fragment = nil

        return urlComponents.URL
    }

    private static func photonURL(forMshotURLComponents urlComponents: NSURLComponents, scaledSize: CGSize) -> NSURL? {
        urlComponents.queryItems = [ NSURLQueryItem(name: ImageURLQueryField.Width, value: "\(Int(scaledSize.width))") ]

        if scaledSize.height != 0 {
            urlComponents.queryItems!.append(NSURLQueryItem(name: ImageURLQueryField.Height, value: "\(Int(scaledSize.height))"))
        }
        return urlComponents.URL
    }

    private static func photonURL(withPhotonURLComponents urlComponents: NSURLComponents, scaledSize: CGSize, forceResize: Bool, quality: UInt) -> NSURL? {
        let useSSL = urlComponents.queryItems!.contains({ queryItem -> Bool in
            return queryItem.name == PhotonQueryFields.SSL && queryItem.value == PhotonSSLValue.Enabled
        })
        urlComponents.queryItems = self.photonQueryItems(forSize: scaledSize, usingSSL: useSSL, forceResize: forceResize, quality: quality)
        return urlComponents.URL
    }

    private static func photonQueryItems(forSize size: CGSize, usingSSL useSSL: Bool, forceResize: Bool, quality: UInt) -> [NSURLQueryItem] {
        var items: [NSURLQueryItem] = []

        // size query item
        if size.height == 0 {
            items.append(NSURLQueryItem(name: ImageURLQueryField.Width, value: "\(Int(size.width))"))
        } else {
            let method = forceResize ? PhotonQueryFields.Resize : PhotonQueryFields.Fit
            items.append(NSURLQueryItem(name: method, value: "\(Int(size.width)),\(Int(size.height))"))
        }

        // ssl
        if useSSL {
            items.append(NSURLQueryItem(name: PhotonQueryFields.SSL, value: PhotonSSLValue.Enabled))
        }

        // quality
        items.append(NSURLQueryItem(name: PhotonQueryFields.Quality, value: "\(quality)"))

        return items
    }
}
