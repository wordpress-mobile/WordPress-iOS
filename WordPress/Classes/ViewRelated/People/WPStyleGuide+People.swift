import Foundation
import WordPressShared

extension WPStyleGuide {
    public struct People {
        public struct RoleBadge {
            // MARK: Metrics
            public static let padding = CGFloat(4)
            public static let borderWidth = CGFloat(1)
            public static let cornerRadius = CGFloat(2)

            // MARK: Typography
            public static var font: UIFont {
                return WPStyleGuide.fontForTextStyle(.caption2)
            }

            // MARK: Colors
            public static let textColor = UIColor.white
        }

        // MARK: Colors
        public static let superAdminColor = WPStyleGuide.fireOrange()
        public static let adminColor = WPStyleGuide.darkGrey()
        public static let editorColor = WPStyleGuide.darkBlue()
        public static let authorColor = WPStyleGuide.wordPressBlue()
        public static let contributorColor = WPStyleGuide.wordPressBlue()
    }
}
