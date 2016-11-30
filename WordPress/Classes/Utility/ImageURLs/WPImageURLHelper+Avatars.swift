//
//  WPImageURLHelper+Avatars.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//  Copyright © 2016 WordPress. All rights reserved.
//

import Foundation

// MARK: {Gr|Bl}avatar URLs

extension WPImageURLHelper
{
    public class func avatarURL(withHash hash: String, type: WPAvatarSourceType, size: CGSize) -> NSURL? {
        var path: String? = nil
        switch type {
        case .Blavatar:
            path = URLComponent.Blavatar.rawValue
            break
        case .Gravatar:
            path = URLComponent.Gravatar.rawValue
            break
        case .Unknown:
            break
        }
        if path == nil {
            path = "/\(hash)"
        } else {
            path = ("/\(path!)" as NSString).stringByAppendingPathComponent(hash)
        }

        let components = NSURLComponents()
        components.scheme = RequestScheme.Insecure.rawValue
        components.host = gravatarURLBase
        components.path = path
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default.rawValue, value: ImageDefaultValue.Identicon.rawValue),
            NSURLQueryItem(name: ImageURLQueryField.Size.rawValue, value: "\(Int(size.width * UIScreen.mainScreen().scale))")
        ]
        return components.URL
    }
}

// MARK: Blavatar URLs

extension WPImageURLHelper
{
    public class func blavatarURL(forHost host: String, size: NSInteger) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(host.md5())
        return blavatarURL(forBlavatarURL: path, size: size)
    }

    public class func blavatarURL(forBlavatarURL path: String, size: NSInteger) -> NSURL? {
        guard let components = NSURLComponents(string: path) else { return nil }
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default.rawValue, value: ImageDefaultValue.None.rawValue),
            NSURLQueryItem(name: ImageURLQueryField.Size.rawValue, value: "\(size)")
        ]
        return components.URL
    }
}

// MARK: Gravatar URLs

extension WPImageURLHelper
{
    /// Returns the Gravatar URL, for a given email, with the specified size + rating.
    ///
    /// - Parameters:
    /// - email: the user's email
    /// - size: required download size
    /// - rating: image rating filtering
    ///
    /// - Returns: Gravatar's URL
    public class func gravatarURL(forEmail email: String, size: NSInteger, rating: String) -> NSURL? {
        let path = (WPGravatarBaseURL as NSString).stringByAppendingPathComponent(email.md5())
        let components = NSURLComponents(string: path)
        components?.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default.rawValue, value: ImageDefaultValue.None.rawValue),
            NSURLQueryItem(name: ImageURLQueryField.Size.rawValue, value: "\(size)"),
            NSURLQueryItem(name: ImageURLQueryField.Rating.rawValue, value: rating)
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

        return components.URL
    }

    public class func gravatarURL(forURL url: NSURL, size: Int) -> NSURL? {
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) else { return nil }
        components.queryItems = [
            NSURLQueryItem(name: ImageURLQueryField.Default.rawValue, value: ImageDefaultValue.None.rawValue),
            NSURLQueryItem(name: ImageURLQueryField.Size.rawValue, value: "\(size)")
        ]
        return components.URL
    }
}
