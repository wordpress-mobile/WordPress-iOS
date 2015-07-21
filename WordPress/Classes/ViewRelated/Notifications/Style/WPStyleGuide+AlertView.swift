import Foundation


extension WPStyleGuide
{
    public struct AlertView
    {
        // MARK: - Title Styles
        public static let titleRegularFont          = WPFontManager.openSansLightFontOfSize(16)
        public static let titleColor                = WPStyleGuide.grey()
        
        
        // MARK: - Detail Styles
        public static let detailsRegularFont        = WPFontManager.openSansRegularFontOfSize(14)
        public static let detailsBoldFont           = WPFontManager.openSansSemiBoldFontOfSize(14)
        public static let detailsColor              = WPStyleGuide.darkGrey()
        
        public static let detailsRegularAttributes  = [
                                                            NSFontAttributeName             : detailsRegularFont,
                                                            NSForegroundColorAttributeName  : detailsColor
                                                      ]
        
        public static let detailsBoldAttributes     = [
                                                            NSFontAttributeName             : detailsBoldFont,
                                                            NSForegroundColorAttributeName  : detailsColor
                                                      ]
        
        // MARK: - Button Styles
        public static let buttonFont                = WPFontManager.openSansRegularFontOfSize(16)
    }
}
