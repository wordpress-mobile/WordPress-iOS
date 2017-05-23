import Foundation
import WordPressShared

extension WPStyleGuide {

    public class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String: AnyObject] {
        return [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: WPStyleGuide.fontForTextStyle(.footnote)
        ]
    }
}
