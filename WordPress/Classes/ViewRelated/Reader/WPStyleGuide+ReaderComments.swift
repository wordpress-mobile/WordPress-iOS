import Foundation
import WordPressShared

extension WPStyleGuide {

    @objc class func defaultSearchBarTextAttributes(_ color: UIColor) -> [String: Any] {
        let attributes = defaultSearchBarTextAttributesSwifted(color)
        return NSAttributedString.Key.convertToRaw(attributes: attributes)
    }

    class func defaultSearchBarTextAttributesSwifted() -> [NSAttributedString.Key: Any] {
        return [
            .font: WPStyleGuide.fixedFont(for: .body)
        ]
    }

    class func defaultSearchBarTextAttributesSwifted(_ color: UIColor) -> [NSAttributedString.Key: Any] {
        var attributes = defaultSearchBarTextAttributesSwifted()

        attributes[.foregroundColor] = color

        return attributes
    }
}
