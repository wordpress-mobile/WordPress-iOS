import Foundation


extension WPStyleGuide
{
    public struct Notifications
    {
        // Styles Used by NotificationsViewController
        //

        //  NoteTableViewCell
        public static let noticonFont               = UIFont(name: "Noticons", size: 16)
        public static let noticonTextColor          = UIColor.whiteColor()
        public static let noticonReadColor          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
        public static let noticonUnreadColor        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)

        public static let noteBackgroundReadColor   = UIColor.whiteColor()
        public static let noteBackgroundUnreadColor = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)

        //  Subject Text
        public static let subjectColor              = WPStyleGuide.littleEddieGrey()
        public static let subjectRegularFont        = WPFontManager.openSansRegularFontOfSize(subjectFontSize)
        public static let subjectBoldFont           = WPFontManager.openSansBoldFontOfSize(subjectFontSize)
        public static let subjectItalicsFont        = WPFontManager.openSansItalicFontOfSize(subjectFontSize)

        public static let subjectRegularStyle       = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectRegularFont,
                                                        NSForegroundColorAttributeName: subjectColor ]

        public static let subjectBoldStyle          = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectBoldFont ]
        
        public static let subjectItalicsStyle       = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectItalicsFont ]

        //  Subject Snippet
        public static let snippetColor              = WPStyleGuide.allTAllShadeGrey()
        public static let snippetRegularStyle       = [ NSParagraphStyleAttributeName:  snippetParagraph,
                                                        NSFontAttributeName:            subjectRegularFont,
                                                        NSForegroundColorAttributeName: snippetColor ]


        // Styles used by NotificationDetailsViewController
        //

        //  Header
        public static let headerFont                = WPStyleGuide.tableviewSectionHeaderFont()
        public static let headerTextColor           = UIColor(red: 0xA7/255.0, green: 0xBB/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
        public static let headerBackgroundColor     = UIColor(red: 0xFF/255.0, green: 0xFF/255.0, blue:0xFF/255.0, alpha: 0xEA/255.0)

        //  Blocks
        public static let blockRegularFont          = WPFontManager.openSansRegularFontOfSize(blockFontSize)
        public static let blockBoldFont             = WPFontManager.openSansBoldFontOfSize(blockFontSize)
        public static let blockItalicsFont          = WPFontManager.openSansItalicFontOfSize(blockFontSize)

        public static let blockTextColor            = WPStyleGuide.littleEddieGrey()
        public static let blockQuotedColor          = UIColor(red: 0x7E/255.0, green: 0x9E/255.0, blue: 0xB5/255.0, alpha: 0xFF/255.0)
        public static let blockBackgroundColor      = UIColor.whiteColor()
        public static let blockLinkColor            = WPStyleGuide.baseLighterBlue()
        public static let blockSubtitleColor        = WPStyleGuide.baseDarkerBlue()
        public static let blockSeparatorColor       = UIColor(red: 0xC8/255.0, green: 0xD6/255.0, blue: 0xE0/255.0, alpha: 0xFF/255.0)
        
        public static let blockUnapprovedSideColor  = UIColor(red: 0xFF/255.0, green: 0xBA/255.0, blue: 0x00/255.0, alpha: 0xFF/255.0)
        public static let blockUnapprovedBgColor    = UIColor(red: 0xFF/255.0, green: 0xBA/255.0, blue: 0x00/255.0, alpha: 0x19/255.0)
        public static let blockUnapprovedTextColor  = UIColor(red: 0xF0/255.0, green: 0x82/255.0, blue: 0x1E/255.0, alpha: 0xFF/255.0)
        
        public static let blockRegularStyle         = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockRegularFont,
                                                        NSForegroundColorAttributeName: blockTextColor]
        
        public static let blockBoldStyle            = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockBoldFont,
                                                        NSForegroundColorAttributeName: blockTextColor]
        
        public static let blockItalicsStyle         = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockItalicsFont,
                                                        NSForegroundColorAttributeName: blockTextColor]

        public static let blockQuotedStyle          = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockItalicsFont,
                                                        NSForegroundColorAttributeName: blockQuotedColor]

        //  Badges
        public static let badgeBackgroundColor      = UIColor.clearColor()

        // Action Buttons
        public static let blockActionDisabledColor  = UIColor(red: 0x7F/255.0, green: 0x9E/255.0, blue: 0xB4/255.0, alpha: 0xFF/255.0)
        public static let blockActionEnabledColor   = UIColor(red: 0xEA/255.0, green: 0x6D/255.0, blue: 0x1B/255.0, alpha: 0xFF/255.0)

        // Helper Methods
        public static func blockParagraphStyleWithIndentation(indentation: CGFloat) -> NSParagraphStyle {
            let paragraph                   = blockParagraph.mutableCopy() as NSMutableParagraphStyle
            paragraph.firstLineHeadIndent   = indentation
            return paragraph
        }

        public static func blockParagraphStyleWithAlignment(alignment: NSTextAlignment) -> NSParagraphStyle {
            let paragraph                   = blockParagraph.mutableCopy() as NSMutableParagraphStyle
            paragraph.alignment             = alignment
            return paragraph
        }

        public static func blockTextColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockTextColor : blockUnapprovedTextColor
        }

        public static func blockSeparatorColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockSeparatorColor : blockUnapprovedSideColor
        }

        public static func blockTimestampColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockQuotedColor : blockUnapprovedTextColor
        }

        //  Private
        private static let subjectFontSize          = CGFloat(14)
        private static let subjectLineSize          = CGFloat(18)
        private static let blockFontSize            = CGFloat(14)
        private static let blockLineSize            = CGFloat(20)

        private static let subjectParagraph         = NSMutableParagraphStyle(
            minLineHeight: subjectLineSize, maxLineHeight: subjectLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
        private static let snippetParagraph         = NSMutableParagraphStyle(
            minLineHeight: subjectLineSize, maxLineHeight: subjectLineSize, lineBreakMode: .ByTruncatingTail, alignment: .Left
        )
        private static let blockParagraph           = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, maxLineHeight: blockLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
    }
}
