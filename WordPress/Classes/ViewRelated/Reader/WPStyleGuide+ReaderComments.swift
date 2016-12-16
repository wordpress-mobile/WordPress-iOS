import Foundation
import DTCoreText
import WordPressShared

extension WPStyleGuide
{

    public class func navbarButtonTintColor() -> UIColor {
        return UIColor(white:1.0, alpha:0.5)
    }

    // Styles used by Comments in the Reader

    public class func commentTitleFont() -> UIFont {
        return WPFontManager.systemBoldFont(ofSize: 14)
    }

    public class func commentBodyFont() -> UIFont {
        return WPFontManager.systemRegularFont(ofSize: 14)
    }

    public class func commentDTCoreTextOptions() -> NSDictionary {
        let defaultStyles = "blockquote { width: 100%; display: block; font-style: italic; }"
        let cssStylesheet:DTCSSStylesheet = DTCSSStylesheet(styleBlock: defaultStyles)
        let fontSize = UIDevice.isPad() ? 16.0 : 14.0
        return [
            DTDefaultFontFamily             : WPRichTextDefaultFontFamily,
            DTDefaultFontName               : WPRichTextDefaultFontName,
            DTDefaultLineHeightMultiplier   : 1.5,
            DTDefaultFontSize               : fontSize,
            DTDefaultTextColor              : WPStyleGuide.littleEddieGrey(),
            DTDefaultLinkColor              : WPStyleGuide.baseLighterBlue(),
            DTDefaultLinkHighlightColor     : WPStyleGuide.midnightBlue(),
            DTDefaultLinkDecoration         : false,
            DTDefaultStyleSheet             : cssStylesheet
        ] as NSDictionary
    }

    public class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String:AnyObject] {
        return [
            NSForegroundColorAttributeName      : color,
            NSFontAttributeName                 : WPFontManager.systemRegularFont(ofSize: 14)
        ]
    }
}
