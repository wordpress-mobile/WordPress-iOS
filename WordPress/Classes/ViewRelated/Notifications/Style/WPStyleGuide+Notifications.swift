import Foundation


extension WPStyleGuide
{
    public struct Notifications
    {
        // MARK: - Styles Used by NotificationsViewController
        //

        //  NoteTableViewHeader
        public static let sectionHeaderBackgroundColor  = UIColor(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 0xEA/255.0)
        
        public static let sectionHeaderRegularStyle = [ NSParagraphStyleAttributeName:  sectionHeaderParagraph,
                                                        NSFontAttributeName:            sectionHeaderFont,
                                                        NSForegroundColorAttributeName: sectionHeaderTextColor ]
        
        //  NoteTableViewCell
        public static let noticonFont               = UIFont(name: "Noticons", size: 16)
        public static let noticonTextColor          = UIColor.whiteColor()
        public static let noticonReadColor          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
        public static let noticonUnreadColor        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
        public static let noticonUnmoderatedColor   = UIColor(red: 0xFF/255.0, green: 0xBA/255.0, blue: 0x00/255.0, alpha: 0xFF/255.0)

        public static let noteBackgroundReadColor   = UIColor.whiteColor()
        public static let noteBackgroundUnreadColor = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)

        public static let noteSeparatorColor        = blockSeparatorColor

        public static let gravatarPlaceholderImage  = UIImage(named: "gravatar")
        
        //  Subject Text
        public static let subjectRegularStyle       = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectRegularFont,
                                                        NSForegroundColorAttributeName: subjectTextColor ]
        
        public static let subjectBoldStyle          = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectBoldFont ]
        
        public static let subjectItalicsStyle       = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectItalicsFont ]

        public static let subjectNoticonStyle       = [ NSParagraphStyleAttributeName:  subjectParagraph,
                                                        NSFontAttributeName:            subjectNoticonFont!,
                                                        NSForegroundColorAttributeName: subjectNoticonColor ]
        
        public static let subjectQuotedStyle        = blockQuotedStyle
        
        //  Subject Snippet
        public static let snippetRegularStyle       = [ NSParagraphStyleAttributeName:  snippetParagraph,
                                                        NSFontAttributeName:            subjectRegularFont,
                                                        NSForegroundColorAttributeName: snippetColor ]

        // MARK: - Styles used by NotificationDetailsViewController
        //

        // Header
        public static let headerTitleColor          = blockTextColor
        public static let headerTitleBoldFont       = blockBoldFont
        
        public static let headerDetailsColor        = blockSubtitleColor
        public static let headerDetailsRegularFont  = blockRegularFont
        
        public static let headerTitleRegularStyle   = [ NSParagraphStyleAttributeName:  headerTitleParagraph,
                                                        NSFontAttributeName:            headerTitleRegularFont,
                                                        NSForegroundColorAttributeName: headerTitleColor]
        
        public static let headerTitleBoldStyle      =  [ NSParagraphStyleAttributeName: headerTitleParagraph,
                                                        NSFontAttributeName:            headerTitleBoldFont,
                                                        NSForegroundColorAttributeName: headerTitleColor]
        
        public static let headerTitleContextStyle   = [ NSParagraphStyleAttributeName:  headerTitleParagraph,
                                                        NSFontAttributeName:            headerTitleItalicsFont,
                                                        NSForegroundColorAttributeName: headerTitleContextColor]
        
        //  Footer
        public static let footerRegularStyle        = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockRegularFont,
                                                        NSForegroundColorAttributeName: footerTextColor]
        
        //  Badges
        public static let badgeBackgroundColor      = UIColor.clearColor()
        public static let badgeLinkColor            = blockLinkColor
        
        public static let badgeRegularStyle         = [ NSParagraphStyleAttributeName:  badgeParagraph,
                                                        NSFontAttributeName:            blockRegularFont,
                                                        NSForegroundColorAttributeName: blockTextColor]
        
        public static let badgeBoldStyle            = blockBoldStyle
        public static let badgeItalicsStyle         = blockItalicsStyle
        public static let badgeQuotedStyle          = blockQuotedStyle
        
        //  Blocks
        public static let blockRegularFont          = WPFontManager.openSansRegularFontOfSize(blockFontSize)
        public static let blockBoldFont             = WPFontManager.openSansBoldFontOfSize(blockFontSize)

        public static let blockTextColor            = WPStyleGuide.littleEddieGrey()
        public static let blockQuotedColor          = UIColor(red: 0x7E/255.0, green: 0x9E/255.0, blue: 0xB5/255.0, alpha: 0xFF/255.0)
        public static let blockBackgroundColor      = UIColor.whiteColor()
        public static let blockLinkColor            = WPStyleGuide.baseLighterBlue()
        public static let blockSubtitleColor        = UIColor(red: 0x00/255.0, green: 0xAA/255.0, blue: 0xDC/255.0, alpha: 0xFF/255.0)
        public static let blockSeparatorColor       = WPStyleGuide.readGrey()

        public static let blockApprovedBgColor      = UIColor.clearColor()
        
        public static let blockUnapprovedSideColor  = UIColor(red: 0xFF/255.0, green: 0xBA/255.0, blue: 0x00/255.0, alpha: 0xFF/255.0)
        public static let blockUnapprovedBgColor    = UIColor(red: 0xFF/255.0, green: 0xBA/255.0, blue: 0x00/255.0, alpha: 0x19/255.0)
        public static let blockUnapprovedTextColor  = UIColor(red: 0xF0/255.0, green: 0x82/255.0, blue: 0x1E/255.0, alpha: 0xFF/255.0)
        
        public static let blockRegularStyle         = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockRegularFont,
                                                        NSForegroundColorAttributeName: blockTextColor ]
        
        public static let blockBoldStyle            = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockBoldFont,
                                                        NSForegroundColorAttributeName: blockTextColor ]
        
        public static let blockItalicsStyle         = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockItalicsFont,
                                                        NSForegroundColorAttributeName: blockTextColor ]
        
        public static let blockQuotedStyle          = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockItalicsFont,
                                                        NSForegroundColorAttributeName: blockQuotedColor ]

        public static let blockMatchStyle           = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockRegularFont,
                                                        NSForegroundColorAttributeName: blockLinkColor ]
        
        public static let blockNoticonStyle         = [ NSParagraphStyleAttributeName:  blockParagraph,
                                                        NSFontAttributeName:            blockNoticonFont!,
                                                        NSForegroundColorAttributeName: blockNoticonColor ]
        
        // Action Buttons
        public static let blockActionDisabledColor  = UIColor(red: 0x7F/255.0, green: 0x9E/255.0, blue: 0xB4/255.0, alpha: 0xFF/255.0)
        public static let blockActionEnabledColor   = UIColor(red: 0xEA/255.0, green: 0x6D/255.0, blue: 0x1B/255.0, alpha: 0xFF/255.0)

        //  RichText Helpers
        public static func blockBackgroundColorForRichText(isBadge: Bool) -> UIColor {
            return isBadge ? badgeBackgroundColor : blockBackgroundColor
        }
        
        //  Comment Helpers
        public static func blockSeparatorColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockSeparatorColor : blockUnapprovedSideColor
        }

        public static func blockBackgroundColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockApprovedBgColor : blockUnapprovedBgColor
        }
        
        public static func blockTitleColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockTextColor : blockUnapprovedTextColor
        }

        public static func blockDetailsColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockQuotedColor : blockUnapprovedTextColor
        }
        
        public static func blockLinkColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockLinkColor : blockUnapprovedTextColor
        }

        
        // MARK: - Constants
        //

        public static let headerFontSize            = CGFloat(12)
        public static let headerLineSize            = CGFloat(16)
        public static let subjectFontSize           = UIDevice.isPad() ? CGFloat(16) : CGFloat(14)
        public static let subjectNoticonSize        = UIDevice.isPad() ? CGFloat(15) : CGFloat(14)
        public static let subjectLineSize           = UIDevice.isPad() ? CGFloat(24) : CGFloat(18)
        public static let snippetLineSize           = subjectLineSize
        public static let blockFontSize             = UIDevice.isPad() ? CGFloat(16) : CGFloat(14)
        public static let blockLineSize             = UIDevice.isPad() ? CGFloat(24) : CGFloat(20)
        public static let maximumCellWidth          = CGFloat(600)


        // MARK: - Private Propreties
        //

        // ParagraphStyle's
        private static let sectionHeaderParagraph   = NSMutableParagraphStyle(
            minLineHeight: headerLineSize, maxLineHeight: headerLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
        private static let subjectParagraph         = NSMutableParagraphStyle(
            minLineHeight: subjectLineSize, maxLineHeight: subjectLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
        private static let snippetParagraph         = NSMutableParagraphStyle(
            minLineHeight: snippetLineSize, maxLineHeight: snippetLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
        private static let headerTitleParagraph     = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, lineBreakMode: .ByTruncatingTail, alignment: .Left
        )
        private static let blockParagraph           = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
        private static let badgeParagraph           = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, maxLineHeight: blockLineSize, lineBreakMode: .ByWordWrapping, alignment: .Center
        )
        
        // Colors
        private static let sectionHeaderTextColor   = UIColor(red: 0xA7/255.0, green: 0xBB/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
        private static let subjectTextColor         = WPStyleGuide.littleEddieGrey()
        private static let subjectNoticonColor      = noticonReadColor
        private static let footerTextColor          = WPStyleGuide.allTAllShadeGrey()
        private static let blockNoticonColor        = WPStyleGuide.allTAllShadeGrey()
        private static let snippetColor             = WPStyleGuide.allTAllShadeGrey()
        private static let headerTitleContextColor  = WPStyleGuide.allTAllShadeGrey()
        
        // Fonts
        private static let sectionHeaderFont        = WPFontManager.openSansBoldFontOfSize(headerFontSize)
        private static let subjectRegularFont       = WPFontManager.openSansRegularFontOfSize(subjectFontSize)
        private static let subjectBoldFont          = WPFontManager.openSansBoldFontOfSize(subjectFontSize)
        private static let subjectItalicsFont       = WPFontManager.openSansItalicFontOfSize(subjectFontSize)
        private static let subjectNoticonFont       = UIFont(name: "Noticons", size: subjectNoticonSize)
        private static let headerTitleRegularFont   = blockRegularFont
        private static let headerTitleItalicsFont   = blockItalicsFont
        private static let blockItalicsFont         = WPFontManager.openSansItalicFontOfSize(blockFontSize)
        private static let blockNoticonFont         = subjectNoticonFont
    }
}
