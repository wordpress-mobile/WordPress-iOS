import UIKit
import WordPressShared
import WordPressUI

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

    public struct ReaderCommentsNotificationSheet {
        static let textColor = UIColor.label
        static let descriptionLabelFont = fontForTextStyle(.subheadline)
        static let switchLabelFont = fontForTextStyle(.body)
        static let buttonTitleLabelFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let buttonBorderColor = UIColor.systemGray3
        static let switchOnTintColor = UIColor.systemGreen
        static let switchInProgressTintColor = UIAppColor.primary
    }
}

private extension NSAttributedString.Key {
    /// Converts a collection of NSAttributedString Attributes, with 'NSAttributedStringKey' instances as 'Keys', into an
    /// equivalent collection that uses regular 'String' instances as keys.
    ///
    static func convertToRaw(attributes: [NSAttributedString.Key: Any]) -> [String: Any] {
        var output = [String: Any]()
        for (key, value) in attributes {
            output[key.rawValue] = value
        }

        return output
    }
}
