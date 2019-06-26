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
        public static let adminColor = UIColor.neutral(shade: .shade700)
        public static let editorColor = UIColor.primary(shade: .shade700)
        public static let otherRoleColor: UIColor = .primary
    }
}
