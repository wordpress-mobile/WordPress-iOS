import Foundation


public struct NotificationColors
{
    public static let iconRead          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
    public static let iconUnread        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
    
    public static let backgroundRead    = UIColor.whiteColor()
    public static let backgroundUnread  = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)
    
    public static let timestamp         = UIColor(red: 0xB7/255.0, green: 0xC9/255.0, blue: 0xD5/255.0, alpha: 0xFF/255.0)
    public static let blockBackground   = UIColor.clearColor()
    public static let blockText         = WPStyleGuide.littleEddieGrey()
    public static let blockLink         = WPStyleGuide.baseLighterBlue()
    public static let quotedText        = WPStyleGuide.allTAllShadeGrey()
}
