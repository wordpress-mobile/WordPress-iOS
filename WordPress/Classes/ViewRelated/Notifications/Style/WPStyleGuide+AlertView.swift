import Foundation
import WordPressShared

extension WPStyleGuide
{
    public struct AlertView
    {
        // MARK: - Title Styles
        public static let titleRegularFont          = WPFontManager.systemLightFontOfSize(16)
        public static let titleColor                = WPStyleGuide.grey()
        
        
        // MARK: - Detail Styles
        public static let detailsRegularFont        = WPFontManager.systemRegularFontOfSize(14)
        public static let detailsBoldFont           = WPFontManager.systemSemiBoldFontOfSize(14)
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
        public static let buttonFont                = WPFontManager.systemRegularFontOfSize(16)
    }
}
