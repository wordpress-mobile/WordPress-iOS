//
//  NSURL+GravatarURL.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//

import Foundation

extension NSURL
{
    func isGravatarURL() -> Bool {
        guard let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host
            where host.hasSuffix(".\(WPImageURLHelper.gravatarURLBase)") else {
                return false
        }

        guard let path = self.path
            where path.hasPrefix("/\(WPImageURLHelper.URLComponent.Gravatar.rawValue)/") else {
                return false
        }

        return true
    }
}
