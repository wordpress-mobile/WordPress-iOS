import Foundation
import WordPressShared

extension WPStyleGuide {

    @objc class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String: Any] {
        let attributes = defaultSearchBarTextAttributesSwifted(color)
        return NSAttributedStringKey.convertToRaw(attributes: attributes)
    }

    class func defaultSearchBarTextAttributesSwifted(_ color: UIColor) -> [NSAttributedStringKey: Any] {
        return [
            .foregroundColor: color,
            .font: WPStyleGuide.fontForTextStyle(.footnote)
        ]
    }
}
