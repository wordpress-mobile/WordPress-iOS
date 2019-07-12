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
            return WPStyleGuide.notoFontForTextStyle(.subheadline)
        }
        public static let enabledColor     = UIColor.primary
        public static let disabledColor    = UIColor.neutral(shade: .shade20)
        public static let placeholderColor = UIColor.neutral(shade: .shade20)
        public static let textColor        = UIColor.text
        public static let separatorColor   = UIColor.neutral(shade: .shade20)
        public static let backgroundColor  = UIColor.neutral(shade: .shade0)
    }
}
