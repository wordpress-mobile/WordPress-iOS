import Foundation
import WordPressShared

extension WPStyleGuide {

    @objc class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String: Any] {
        let attributes = defaultSearchBarTextAttributesSwifted(color)
        return NSAttributedString.Key.convertToRaw(attributes: attributes)
    }

    class func defaultSearchBarTextAttributesSwifted(_ color: UIColor) -> [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: color,
            .font: WPStyleGuide.fixedFont(for: .footnote)
        ]
    }
}
