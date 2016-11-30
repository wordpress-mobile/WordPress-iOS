//
//  NSString+BlavatarURL.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//

import Foundation

extension NSString
{
    func isBlavatarURL() -> Bool {
        return self.containsString("\(WPImageURLHelper.gravatarURLBase)/\(WPImageURLHelper.URLComponent.Blavatar.rawValue)")
    }
}
