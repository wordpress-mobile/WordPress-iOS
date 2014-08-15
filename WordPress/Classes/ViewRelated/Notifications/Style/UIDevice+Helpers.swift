//
//  UIDevice+Helpers.swift
//  WordPress
//
//  Created by Jorge Leandro Perez on 8/14/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

import Foundation


extension UIDevice
{
    public class func isPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
}