import Foundation
import MGImageUtilities
import WordPressShared

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
        public static func gravatarPlaceholderImage(isApproved approved: Bool) -> UIImage {
            return approved ? gravatarApproved : gravatarUnapproved
        }
        
        public static func separatorsColor(isApproved approved: Bool) -> UIColor {
            return approved ? WPStyleGuide.readGrey() : WPStyleGuide.alertYellowDark()
        }
        
        public static func detailsRegularStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertYellowDark()
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleRegularFont,
                        NSForegroundColorAttributeName  : color ]
        }

        public static func detailsRegularRedStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleRegularFont,
                        NSForegroundColorAttributeName  : color ]
        }

        public static func detailsItalicsStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleItalicsFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func detailsBoldStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()
            
            return  [   NSParagraphStyleAttributeName   : titleParagraph,
                        NSFontAttributeName             : titleBoldFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func timestampStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.allTAllShadeGrey() : WPStyleGuide.alertYellowDark()
            
            return  [   NSFontAttributeName             : timestampFont,
                        NSForegroundColorAttributeName  : color ]
        }
        
        public static func backgroundColor(isApproved approved: Bool) -> UIColor {
            return approved ? UIColor.whiteColor() : WPStyleGuide.alertYellowLighter()
        }
        
        public static func timestampImage(isApproved approved: Bool) -> UIImage {
            let timestampImage = UIImage(named: "reader-postaction-time")!
            return approved ? timestampImage : timestampImage.imageTintedWithColor(WPStyleGuide.alertYellowDark())
        }



        // MARK: - Private Properties
        //
        private static let gravatarApproved     = UIImage(named: "gravatar")!
        private static let gravatarUnapproved   = UIImage(named: "gravatar-unapproved")!
        
        private static let timestampFont        = WPStyleGuide.subtitleFont()
        
        private static let titleFontSize        = CGFloat(14)
        private static let titleRegularFont     = WPFontManager.systemRegularFontOfSize(titleFontSize)
        private static let titleBoldFont        = WPFontManager.systemSemiBoldFontOfSize(titleFontSize)
        private static let titleItalicsFont     = WPFontManager.systemItalicFontOfSize(titleFontSize)
        
        private static let titleLineSize        = CGFloat(18)
        private static let titleParagraph       = NSMutableParagraphStyle(minLineHeight: titleLineSize,
                                                    maxLineHeight:  titleLineSize,
                                                    lineBreakMode:  .ByWordWrapping,
                                                    alignment:      .Left)
    }
}
