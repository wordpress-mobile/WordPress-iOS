import Foundation


extension Notification
{
    public struct Fonts
    {
        public static let noticon           = UIFont(name: "Noticons", size: 16)
        public static let timestamp         = WPFontManager.openSansRegularFontOfSize(14)
        
        public static let subjectRegular    = WPFontManager.openSansRegularFontOfSize(14)
        public static let subjectBold       = WPFontManager.openSansBoldFontOfSize(14)
        public static let subjectItalics    = WPFontManager.openSansItalicFontOfSize(14)
        
        public static let blockFontSize     = CGFloat(UIDevice.isPad() ? 18 : 16)
        public static let blockRegular      = WPFontManager.openSansRegularFontOfSize(blockFontSize)
        public static let blockBold         = WPFontManager.openSansBoldFontOfSize(blockFontSize)
        public static let blockItalics      = WPFontManager.openSansItalicFontOfSize(blockFontSize)
    }

    public struct Colors
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

    public struct Styles
    {
        private static let subjectParagraphStyle    = NSMutableParagraphStyle(minimumLineHeight: 18, maximumLineHeight: 18)
        private static let blockParagraphStyle      = NSMutableParagraphStyle(minimumLineHeight: 24, maximumLineHeight: 24)
        
        public static let subjectRegular    = NSDictionary(objectsAndKeys:
            subjectParagraphStyle,              NSParagraphStyleAttributeName,
            Fonts.subjectRegular,               NSFontAttributeName
        )
        
        public static let subjectBold       = NSDictionary(objectsAndKeys:
            subjectParagraphStyle,              NSParagraphStyleAttributeName,
            Fonts.subjectBold,                  NSFontAttributeName
        )
        
        public static let subjectItalics    = NSDictionary(objectsAndKeys:
            subjectParagraphStyle,              NSParagraphStyleAttributeName,
            Fonts.subjectItalics,               NSFontAttributeName
        )
        
        public static let blockRegular      = NSDictionary(objectsAndKeys:
            blockParagraphStyle,                NSParagraphStyleAttributeName,
            Fonts.blockRegular,                 NSFontAttributeName,
            Colors.blockText,                   NSForegroundColorAttributeName
        )
        
        public static let blockBold         = NSDictionary(objectsAndKeys:
            blockParagraphStyle,                NSParagraphStyleAttributeName,
            Fonts.blockBold,                    NSFontAttributeName,
            Colors.blockText,                   NSForegroundColorAttributeName
        )
        
        public static let blockItalics      = NSDictionary(objectsAndKeys:
            blockParagraphStyle,                NSParagraphStyleAttributeName,
            Fonts.blockItalics,                 NSFontAttributeName,
            Colors.blockText,       NSForegroundColorAttributeName
        )
        
        public static let quotedItalics     = NSDictionary(objectsAndKeys:
            blockParagraphStyle,                NSParagraphStyleAttributeName,
            Fonts.blockItalics,                 NSFontAttributeName,
            Colors.quotedText,                  NSForegroundColorAttributeName
        )
    }
}