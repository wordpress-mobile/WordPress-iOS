import Foundation
import WordPressShared

extension WPStyleGuide {

    public class func navbarButtonTintColor() -> UIColor {
        return UIColor(white: 1.0, alpha: 0.5)
    }

    // Styles used by Comments in the Reader

    public class func commentTitleFont() -> UIFont {
        return WPFontManager.systemBoldFont(ofSize: 14)
    }

    public class func commentBodyFont() -> UIFont {
        return WPFontManager.systemRegularFont(ofSize: 14)
    }

    public class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String: AnyObject] {
        return [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: WPFontManager.systemRegularFont(ofSize: 14)
        ]
    }
}
