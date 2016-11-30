//
//  WPImageURLHelper+SiteIcons.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//

import Foundation

extension WPImageURLHelper
{
    private static let defaultBlavatarSize: CGFloat = 40

    /// Transform a site icon URL to contain a size query specifying the width and height of the square.
    ///
    /// - parameters:
    ///     - path: the original site icon URL
    ///     - size: the square size of the image to download
    ///
    /// - returns: the original URL with the size query appended, or `nil` if the URL is invalid
    public class func siteIconURL(forSiteIconURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else {
            return nil
        }
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Height.rawValue, value: "\(size)"),
            NSURLQueryItem(name: ImageURLQueryField.Width.rawValue, value: "\(size)")
        ]
        return components.URL
    }

    /// Construct the URL for a site icon using data extracted from a `ReaderPostContentProvided`, 
    /// namely the site icon URl or blog URL.
    ///
    /// - parameters:
    ///     - contentProvider: the object conforming to the `ReaderPostContentProvided` protocol
    ///     - size: the square size of the image to download
    ///
    /// - returns: the URL for the site icon of specified size, or `nil` if the URL is invalid, 
    /// or `contentProvider` does not contain a siteIconURL or blogURL,
    public class func siteIconURL(forContentProvider contentProvider: ReaderPostContentProvider, size: Int) -> NSURL? {
        if (contentProvider.siteIconURL() == nil || contentProvider.siteIconURL().characters.count == 0) {
            guard
                let blogURL = contentProvider.blogURL(),
                let hash = NSURL(string: blogURL)?.host?.md5()
            else {
                return nil
            }

            let components = NSURLComponents()
            components.host = GravatarDefaults.host
            components.scheme = GravatarDefaults.scheme
            components.path = ["", URLComponent.Blavatar.rawValue, hash].joinWithSeparator("/")
            components.queryItems = commonQueryItems(withSize: size)
            return components.URL
        }

        if !contentProvider.siteIconURL().containsString("/\(URLComponent.Blavatar.rawValue)/") {
            return NSURL(string: contentProvider.siteIconURL())
        }

        let components = NSURLComponents(string: contentProvider.siteIconURL())
        components?.queryItems = commonQueryItems(withSize: size)
        return components?.URL
    }

    /// Given a site path and bounds for a `UIImageView`, construct the URL to the
    /// site's icon image of appropriate size.
    ///
    /// - parameters:
    ///     - path: the path to the original site icon image
    ///     - bounds: the `CGRect` in which the image will be displayed
    ///
    /// - returns: a URL derived from the original URL with a size query appended
    public class func siteIconURL(forPath path: String?, imageViewBounds bounds: CGRect?) -> NSURL? {
        guard
            let path = path,
            let bounds = bounds,
            let url = NSURL(string: path),
            let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        else {
            return nil
        }

        let size = blavatarSizeInPoints(forImageViewBounds: bounds)
        components.queryItems = commonQueryItems(withSize: size)
        return components.URL
    }

    /// Computes the size needed for a blavatar to fit inside a specified `CGRect` 
    /// (usually that of a `UIImageView`). If the `CGRect`'s size is `.zero`, then
    /// the default blavatar size is returned; otherwise, the maximum of its
    /// width or height is returned.
    public static func blavatarSizeInPoints(forImageViewBounds bounds: CGRect) -> Int {
        var size = defaultBlavatarSize

        if !CGSizeEqualToSize(bounds.size, .zero) {
            size = max(bounds.width, bounds.height)
        }

        return Int(size * UIScreen.mainScreen().scale)
    }

    private static func commonQueryItems(withSize size: Int) -> [NSURLQueryItem] {
        return [
            NSURLQueryItem(name: ImageURLQueryField.Default.rawValue, value: ImageDefaultValue.None.rawValue),
            NSURLQueryItem(name: ImageURLQueryField.Size.rawValue, value: "\(size)")
        ]
    }
}
