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
    private static let acceptedImageTypes = ["gif", "jpg", "jpeg", "png"]

    private enum PhotonSubdomain: String {
        case Zero = "i0"
        case One = "i1"
        case Two = "i2"
    }

    private enum PhotonQueryFields: String {
        case SSL = "ssl"
        case Quality = "quality"
        case Resize = "resize"
        case Fit = "fit"
        case Crop = "crop"
        case AddLetterbox = "lb"
        case RemoveLetterBox = "ulb"
        case Filter = "filter"
        case Brightness = "brightness"
        case Contrast = "contrast"
        case Colorize = "colorize"
        case Smooth = "smooth"
        case Zoom = "zoom"
        case Strip = "strip"
    }

    private enum PhotonFilterValue: String {
        case Negate = "negate"
        case Grayscale = "grayscale"
        case Sepia = "sepia"
        case EdgeDetect = "edgedetect"
        case Emboss = "emboss"
        case BlurGaussian = "blurgaussian"
        case BlurSelective = "blurselective"
        case MeanRemoval = "meanremoval"
    }

    private enum PhotonStipValue: String {
        case All = "all"
    }

    private enum PhotonSSLValue: String {
        case Enabled = "1"
    }

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
        guard
            let urlString = url.absoluteString,
            let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true),
            let urlPath = urlComponents.path
            else {
                return url
        }

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
        if urlString.isPhotonURL() {
            if urlComponents.queryItems != nil {
                let useSSL = urlComponents.queryItems!.contains({ queryItem -> Bool in
                    return queryItem.name == PhotonQueryFields.SSL.rawValue && queryItem.value == PhotonSSLValue.Enabled.rawValue
                })
                urlComponents.queryItems = self.photonQueryItems(forSize: scaledSize, usingSSL: useSSL, forceResize: forceResize, quality: boundedQuality)
                return urlComponents.URL
            }

            // Saftey net. Don't photon photon!
            return url
        }

        // Photon rejects resizing mshots
        if urlPath.containsString("/mshots/") {
            urlComponents.queryItems = [ NSURLQueryItem(name: ImageURLQueryField.Width.rawValue, value: "\(Int(size.width))") ]

            if scaledSize.height != 0 { // ???: the original only tested for equality to 0. What if height < 0?
                urlComponents.queryItems!.append(NSURLQueryItem(name: ImageURLQueryField.Height.rawValue, value: "\(Int(size.height))"))
            }
            return urlComponents.URL
        }

        // Strip original resizing parameters, or we might get an image too small
        urlComponents.scheme = RequestScheme.Secure.rawValue
        urlComponents.host = "\(PhotonSubdomain.Zero.rawValue).\(wordpressURLBase)"
        urlComponents.queryItems = photonQueryItems(forSize: scaledSize, usingSSL: url.scheme == RequestScheme.Secure.rawValue, forceResize: forceResize, quality: boundedQuality)
        return urlComponents.URL
    }

    private static func photonQueryItems(forSize size: CGSize, usingSSL useSSL: Bool, forceResize: Bool, quality: UInt) -> [NSURLQueryItem] {
        var items: [NSURLQueryItem] = []

        // size query item
        if size.height == 0 {
            items.append(NSURLQueryItem(name: ImageURLQueryField.Width.rawValue, value: "\(size.width)"))
        } else {
            let method = forceResize ? PhotonQueryFields.Resize : PhotonQueryFields.Fit
            items.append(NSURLQueryItem(name: method.rawValue, value: "\(Int(size.width)),\(Int(size.height))"))
        }

        // ssl
        if useSSL {
            items.append(NSURLQueryItem(name: PhotonQueryFields.SSL.rawValue, value: PhotonSSLValue.Enabled.rawValue))
        }

        // quality
        items.append(NSURLQueryItem(name: PhotonQueryFields.Quality.rawValue, value: "\(quality)"))

        return items
    }
}
