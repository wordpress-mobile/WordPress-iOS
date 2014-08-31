import Foundation


extension WPStyleGuide
{
    public struct Comments
    {
        public struct Fonts
        {
            private static let replyFontSize    = CGFloat(14)
            public static let replyButton       = WPFontManager.openSansBoldFontOfSize(13)
            public static let replyText         = WPFontManager.openSansRegularFontOfSize(replyFontSize)
        }

        public struct Colors
        {
            public static let replyEnabled      = WPStyleGuide.newKidOnTheBlockBlue()
            public static let replyDisabled     = UIColor(red: 0xA1/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
            public static let replyPlaceholder  = UIColor(red: 0xC6/255.0, green: 0xD5/255.0, blue: 0xDF/255.0, alpha: 0xFF/255.0)
            public static let replyText         = WPStyleGuide.littleEddieGrey()
            public static let replySeparator    = UIColor(red: 0xA3/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
            public static let replyBackground   = UIColor(red: 0xF1/255.0, green:0xF6/255.0, blue:0xF9/255.0, alpha:0xFF/255.0)
        }
    }
}
