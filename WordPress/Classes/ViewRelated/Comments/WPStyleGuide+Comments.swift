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
        public static let titleRegularStyle         = [ NSParagraphStyleAttributeName:  titleParagraph,
                                                        NSFontAttributeName:            titleRegularFont,
                                                        NSForegroundColorAttributeName: titleTextColor ]

        public static let titleBoldStyle            = [ NSParagraphStyleAttributeName:  titleParagraph,
                                                        NSFontAttributeName:            titleBoldFont,
                                                        NSForegroundColorAttributeName: titleTextColor ]
        
        public static let timestampFont             = WPStyleGuide.subtitleFont()
        public static let timestampColor            = WPStyleGuide.allTAllShadeGrey()
        public static let gravatarPlaceholderImage  = UIImage(named: "gravatar")
        
        
        // MARK: - Private Properties Properties
        //
        private static let titleFontSize            = CGFloat(14)
        private static let titleRegularFont         = WPFontManager.openSansRegularFontOfSize(titleFontSize)
        private static let titleBoldFont            = WPFontManager.openSansSemiBoldFontOfSize(titleFontSize)
        
        private static let titleTextColor           = WPStyleGuide.littleEddieGrey()
        private static let titleLineSize            = CGFloat(18)
        private static let titleParagraph           = NSMutableParagraphStyle(
            minLineHeight: titleLineSize, maxLineHeight: titleLineSize, lineBreakMode: .ByWordWrapping, alignment: .Left
        )
    }
}
