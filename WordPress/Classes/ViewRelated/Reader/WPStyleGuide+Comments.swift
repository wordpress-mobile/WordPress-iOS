import Foundation


extension WPStyleGuide
{

    public class func navbarButtonTintColor() -> UIColor {
        return UIColor(white:1.0, alpha:0.5)
    }

    // Styles used by Comments in the Reader

    public class func commentTitleFont() -> UIFont {
        return WPFontManager.openSansBoldFontOfSize(14)
    }

    public class func commentBodyFont() -> UIFont {
        return WPFontManager.openSansRegularFontOfSize(14)
    }

    public class func commentDTCoreTextOptions() -> NSDictionary {
        let defaultStyles = "blockquote { width: 100%; display: block; font-style: italic; }"
        let cssStylesheet:DTCSSStylesheet = DTCSSStylesheet(styleBlock: defaultStyles);
        let fontSize = UIDevice.isPad() ? 16.0 : 14.0;
        return [
            DTDefaultFontFamily             : "Merriweather Light",
            DTDefaultLineHeightMultiplier   : 1.5,
            DTDefaultFontSize               : fontSize,
            DTDefaultTextColor              : WPStyleGuide.littleEddieGrey(),
            DTDefaultLinkColor              : WPStyleGuide.baseLighterBlue(),
            DTDefaultLinkHighlightColor     : WPStyleGuide.midnightBlue(),
            DTDefaultLinkDecoration         : false,
            DTDefaultStyleSheet             : cssStylesheet
        ] as NSDictionary
    }

    public class func defaultSearchBarTextAttributes(color: UIColor) -> NSDictionary {
        return [
            NSForegroundColorAttributeName      : color,
            NSFontAttributeName                 : WPFontManager.openSansRegularFontOfSize(14)
        ] as NSDictionary
    }
}
