import Foundation
import WordPressShared

extension WPStyleGuide {
    public struct Reply {
        // Styles used by ReplyTextView
        //
        public static var buttonFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitBold)
        }
        public static var textFont: UIFont {
            return WPStyleGuide.regularTextFont()
        }

        public static let enabledColor       = UIColor.primary
        public static let disabledColor      = UIColor.listSmallIcon
        public static let placeholderColor   = UIColor.textPlaceholder
        public static let textColor          = UIColor.text
        public static let separatorColor     = UIColor.divider
        public static let textViewBackground = UIColor.basicBackground
        public static let backgroundColor    = UIColor.basicBackground
    }
}
