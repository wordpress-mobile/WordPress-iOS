import Foundation

import WordPressShared

/// This class groups all of the styles used by all of the CommentsViewController.
///
extension WPStyleGuide {
    public struct Comments {

        static let gravatarPlaceholderImage = UIImage(named: "gravatar") ?? UIImage()
        static let backgroundColor = UIColor.listForeground

        static let detailFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let detailTextColor = UIColor.textSubtle

        private static let titleTextColor = UIColor.text
        private static let titleTextStyle = UIFont.TextStyle.headline

        static let titleBoldAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(titleTextStyle, fontWeight: .semibold),
            .foregroundColor: titleTextColor
        ]

        static let titleRegularAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(titleTextStyle, fontWeight: .regular),
            .foregroundColor: titleTextColor
        ]

        static func timestampStyle(isApproved approved: Bool) -> [NSAttributedString.Key: Any] {
            return  [.font: WPStyleGuide.fontForTextStyle(.caption1),
                     .foregroundColor: UIColor.textSubtle ]
        }

        static func timestampImage(isApproved approved: Bool) -> UIImage {
            guard let timestampImage = UIImage(named: "reader-postaction-time") else {
                return UIImage()
            }
            return approved ? timestampImage : timestampImage.withRenderingMode(.alwaysTemplate)
        }
    }
}
