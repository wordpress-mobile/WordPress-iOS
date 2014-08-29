import Foundation


extension WPStyleGuide
{
    public struct Notifications
    {
        public struct Fonts
        {
            public static let noticon           = UIFont(name: "Noticons", size: 16)
            public static let timestamp         = WPFontManager.openSansRegularFontOfSize(14)
            public static let header            = WPStyleGuide.tableviewSectionHeaderFont()
            public static let reply             = WPFontManager.openSansBoldFontOfSize(13)

            private static let subjectSize      = CGFloat(14)
            public static let subjectRegular    = WPFontManager.openSansRegularFontOfSize(subjectSize)
            public static let subjectBold       = WPFontManager.openSansBoldFontOfSize(subjectSize)
            public static let subjectItalics    = WPFontManager.openSansItalicFontOfSize(subjectSize)
            
            private static let blockSizeMedium  = CGFloat(UIDevice.isPad() ? 16 : 14)
            public static let blockRegular      = WPFontManager.openSansRegularFontOfSize(blockSizeMedium)
            public static let blockBold         = WPFontManager.openSansBoldFontOfSize(blockSizeMedium)
            public static let blockItalics      = WPFontManager.openSansItalicFontOfSize(blockSizeMedium)
        }

        public struct Colors
        {
            public static let iconRead          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
            public static let iconUnread        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
            
            public static let header            = UIColor(red: 0xA7/255.0, green: 0xBB/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
            public static let headerBackground  = UIColor(red: 0xFF/255.0, green: 0xFF/255.0, blue:0xFF/255.0, alpha: 0xEA/255.0)
            
            public static let backgroundRead    = UIColor.whiteColor()
            public static let backgroundUnread  = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)
            
            public static let timestamp         = UIColor(red: 0xB7/255.0, green: 0xC9/255.0, blue: 0xD5/255.0, alpha: 0xFF/255.0)

            public static let replyEnabled      = UIColor(red: 0xA1/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
            public static let replyDisabled     = WPStyleGuide.newKidOnTheBlockBlue()
            public static let replyPlaceholder  = UIColor(red: 0xC6/255.0, green: 0xD5/255.0, blue: 0xDF/255.0, alpha: 0xFF/255.0)
            public static let replySeparator    = UIColor(red: 0xA3/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)

            public static let blockBackground   = UIColor.whiteColor()
            public static let blockText         = WPStyleGuide.littleEddieGrey()
            public static let blockLink         = WPStyleGuide.baseLighterBlue()
            public static let blockHeader       = blockText
            public static let blockSubtitle     = WPStyleGuide.baseDarkerBlue()
            
            public static let quotedText        = WPStyleGuide.allTAllShadeGrey()
            
            public static let replyBackground   = UIColor(red: 0xF1/255.0, green:0xF6/255.0, blue:0xF9/255.0, alpha:0xFF/255.0)

            public static let actionOffText     = UIColor(red: 0x7F/255.0, green: 0x9E/255.0, blue: 0xB4/255.0, alpha: 0xFF/255.0)
            public static let actionOnText      = UIColor(red: 0xEA/255.0, green: 0x6D/255.0, blue: 0x1B/255.0, alpha: 0xFF/255.0)
        }

        public struct Styles
        {
            private static let subjectParagraph = NSMutableParagraphStyle(minLineHeight: 18, maxLineHeight: 18, lineBreakMode: .ByWordWrapping)
            private static let snippetParagraph = NSMutableParagraphStyle(minLineHeight: 18, maxLineHeight: 18, lineBreakMode: .ByTruncatingTail)
            private static let blockParagraph   = NSMutableParagraphStyle(minLineHeight: 20, maxLineHeight: 20, lineBreakMode: .ByWordWrapping)
            
            public static let subjectRegular    = NSDictionary(objectsAndKeys:
                subjectParagraph,                   NSParagraphStyleAttributeName,
                Fonts.subjectRegular,               NSFontAttributeName
            )
            
            public static let subjectBold       = NSDictionary(objectsAndKeys:
                subjectParagraph,                   NSParagraphStyleAttributeName,
                Fonts.subjectBold,                  NSFontAttributeName
            )
            
            public static let subjectItalics    = NSDictionary(objectsAndKeys:
                subjectParagraph,                   NSParagraphStyleAttributeName,
                Fonts.subjectItalics,               NSFontAttributeName
            )

            public static let snippetRegular    = NSDictionary(objectsAndKeys:
                snippetParagraph,                   NSParagraphStyleAttributeName,
                Fonts.subjectRegular,               NSFontAttributeName,
                Colors.quotedText,                  NSForegroundColorAttributeName
            )

            public static let blockRegular      = NSDictionary(objectsAndKeys:
                blockParagraph,                     NSParagraphStyleAttributeName,
                Fonts.blockRegular,                 NSFontAttributeName,
                Colors.blockText,                   NSForegroundColorAttributeName
            )
            
            public static let blockBold         = NSDictionary(objectsAndKeys:
                blockParagraph,                     NSParagraphStyleAttributeName,
                Fonts.blockBold,                    NSFontAttributeName,
                Colors.blockText,                   NSForegroundColorAttributeName
            )
            
            public static let blockItalics      = NSDictionary(objectsAndKeys:
                blockParagraph,                     NSParagraphStyleAttributeName,
                Fonts.blockItalics,                 NSFontAttributeName,
                Colors.blockText,                   NSForegroundColorAttributeName
            )

            public static func blockParagraphStyle(indentation: CGFloat) -> NSParagraphStyle {
                let paragraph                   = blockParagraph.mutableCopy() as NSMutableParagraphStyle
                paragraph.firstLineHeadIndent   = indentation
                return paragraph
            }
        }
    }
}
