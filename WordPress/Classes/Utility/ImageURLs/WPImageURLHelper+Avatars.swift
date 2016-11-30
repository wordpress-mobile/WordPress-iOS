//
//  WPImageURLHelper+Avatars.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//

import Foundation

// MARK: {Gr|Bl}avatar URLs

extension WPImageURLHelper
{
    /// Construct a URL for an avatar given the type of avatar, the hash and  desired size.
    ///
    /// - parameters:
    ///     - hash: the precomputed hash for the avatar
    ///     - type: type of the avatar, see `WPAvatarSourceType`
    ///     - size: the size of avatar to be retrieved from the server
    ///
    /// - returns: the URL for the avatar of given type/size, or `nil` if the URL could not be constructed (for instance, if one of the components turns out to be invalid)
    public class func avatarURL(withHash hash: String, type: WPAvatarSourceType, size: CGSize) -> NSURL? {
        let components = NSURLComponents()
        components.scheme = RequestScheme.Insecure
        components.host = gravatarURLBase
        components.path = avatarPath(withHash: hash, type: type)
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default, value: ImageDefaultValue.Identicon),
            NSURLQueryItem(name: ImageURLQueryField.Size, value: "\(Int(size.width * UIScreen.mainScreen().scale))")
        ]
        return components.URL
    }

    private class func avatarPath(withHash hash: String, type: WPAvatarSourceType) -> String? {
        var path: String? = nil

        switch type {
        case .Blavatar:
            path = URLComponent.Blavatar
            break
        case .Gravatar:
            path = URLComponent.Gravatar
            break
        case .Unknown:
            break
        }

        if path == nil {
            path = "/\(hash)"
        } else {
            path = ("/\(path!)" as NSString).stringByAppendingPathComponent(hash)
        }

        return path
    }
}

// MARK: Blavatar URLs

extension WPImageURLHelper
{
    /// Construct the URL for a blavatar given the blog host and desired square image size.
    ///
    /// - parameters:
    ///     - host: the blog host, e.g. myblog.wordpress.com
    ///     - size: square size of the image to retrieve
    ///
    /// - returns: the blavatar URL, or `nil` if the URL is invalid, e.g. if `host` is not a valid web host
    public class func blavatarURL(forHost host: String, size: NSInteger) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(host.md5())
        return blavatarURL(forBlavatarURL: path, size: size)
    }

    /// Construct URL for a blavatar given the host/path and desired square image size.
    ///
    /// - parameters:
    ///     - path: the host/path of the image, e.g. myblog.wordpress.com/image.jpg
    ///     - size: square size of the image to retrieve
    ///
    /// - returns: the blavatar URL, or `nil` if the URL is invalid, e.g. if `path` is not a valid internet path
    public class func blavatarURL(forBlavatarURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else {
            return nil
        }
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default, value: ImageDefaultValue.None),
            NSURLQueryItem(name: ImageURLQueryField.Size, value: "\(size)")
        ]
        return components.URL
    }

    /// - returns: `true` if `url` is a blavatar URL, specifically if it contains "gravatar.com/blavatar", and `false` otherwise
    public class func isBlavatarURL(url: NSString) -> Bool {
        return url.containsString("\(gravatarURLBase)/\(URLComponent.Blavatar)")
    }
}

// MARK: Gravatar URLs

extension WPImageURLHelper
{
    /// Returns the Gravatar URL, for a given email, with the specified size + rating.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - size: required download size
    ///     - rating: image rating filtering
    ///
    /// - Returns: Gravatar's URL
    public class func gravatarURL(forEmail email: String, size: NSInteger, rating: String) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(email.md5())
        let components = NSURLComponents(string: path)
        components?.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default, value: ImageDefaultValue.None),
            NSURLQueryItem(name: ImageURLQueryField.Size, value: "\(size)"),
            NSURLQueryItem(name: ImageURLQueryField.Rating, value: rating)
        ]
        return components?.URL
    }

    /// Transform a gravatar URL into canonical form, by prepending "secure." to the host and using the "https" scheme.
    ///
    /// - parameter url: the original gravatar URL to transform
    ///
    /// - returns: the transformed URL or `nil` if the URL is invalid or the hash in the original URL's path is computed from "unknown@gravatar.com"
    public class func gravatarURL(forURL url: NSURL) -> NSURL? {
        guard isGravatarURL(url) else {
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

        return components.URL
    }

    /// Transform a gravatar URL to a form that can request the gravatar of the specified size.
    ///
    /// - parameters:
    ///     - url: the original gravatar URL to add size query onto
    ///     - size: the desired size of the image to download
    ///
    /// - returns: the transformed URL or `nil` if the URL is invalid
    public class func gravatarURL(forURL url: NSURL, size: Int) -> NSURL? {
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default, value: ImageDefaultValue.None),
            NSURLQueryItem(name: ImageURLQueryField.Size, value: "\(size)")
        ]
        return components.URL
    }

    /// - returns: `true` if the URL's host has the suffix "gravatar.com" and the path contains "/gravatar/"
    public class func isGravatarURL(url: NSURL) -> Bool {
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host
            where host.hasSuffix(".\(gravatarURLBase)") else {
                return false
        }

        guard let path = url.path
            where path.hasPrefix("/\(URLComponent.Gravatar)/") else {
                return false
        }

        return true
    }
}
