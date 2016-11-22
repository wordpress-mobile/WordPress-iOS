//
//  NSString+PhotonURL.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/22/16.
//  Copyright © 2016 WordPress. All rights reserved.
//

import Foundation

extension NSString
{
    // Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    func isPhotonURL() -> Bool {
        return self.containsString(".wp.com")
    }
}
