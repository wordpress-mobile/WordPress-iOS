import Foundation


/**
*  @class           WPStyleGuide+Comments
*  @brief           This class groups all of the styles used by all of the CommentsViewController.
*/

extension WPStyleGuide
{
    public struct Comments
    {
        // MARK: - Public Properties
        //
        public static let gravatarApprovedImage     = UIImage(named: "gravatar")!
        public static let gravatarUnapprovedImage   = UIImage(named: "gravatar-unapproved")!
        
        public static func gravatarPlaceholderImage(isApproved approved: Bool) -> UIImage {
            return approved ? gravatarApprovedImage : gravatarUnapprovedImage
        }
        
        public static func separatorsColor(isApproved approved: Bool) -> UIColor {
            return approved ? WPStyleGuide.readGrey() : alertYellowDark
        }
        
        public static func detailsRegularStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : alertYellowDark
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleRegularFont,
                        NSForegroundColorAttributeName  : color ]
        }

        public static func detailsRegularRedStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : alertRedDarker
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleRegularFont,
                        NSForegroundColorAttributeName  : color ]
        }

        public static func detailsItalicsStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : alertRedDarker
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleItalicsFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func detailsBoldStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : alertRedDarker
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleBoldFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func timestampStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.allTAllShadeGrey() : alertYellowDark
            
            return  [   NSFontAttributeName             : timestampFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func backgroundColor(isApproved approved: Bool) -> UIColor {
            return approved ? UIColor.whiteColor() : alertYellowLighter
        }
        
        public static func timestampImage(isApproved approved: Bool) -> UIImage {
            let timestampImage = UIImage(named: "reader-postaction-time")!
            return approved ? timestampImage : timestampImage.imageTintedWithColor(alertYellowDark)
        }
        
        
        // MARK: - New Colors
        //
        public static let alertYellowDark       = UIColor(red: 0xF0/255.0, green: 0xB8/255.0, blue: 0x49/255.0, alpha: 0xFF/255.0)
        public static let alertYellowLighter    = UIColor(red: 0xFE/255.0, green: 0xF8/255.0, blue: 0xEE/255.0, alpha: 0xFF/255.0)
        public static let alertRedDarker        = UIColor(red: 0x6D/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 0xFF/255.0)

        
        // MARK: - Private Properties Properties
        //
        private static let timestampFont        = WPStyleGuide.subtitleFont()
        
        private static let titleFontSize        = CGFloat(14)
        private static let titleRegularFont     = WPFontManager.openSansRegularFontOfSize(titleFontSize)
        private static let titleBoldFont        = WPFontManager.openSansSemiBoldFontOfSize(titleFontSize)
        private static let titleItalicsFont     = WPFontManager.openSansItalicFontOfSize(titleFontSize)
        
        private static let titleLineSize        = CGFloat(18)
        private static let titleParagraph       = NSMutableParagraphStyle(
            minLineHeight: titleLineSize, maxLineHeight: titleLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
    }
}
