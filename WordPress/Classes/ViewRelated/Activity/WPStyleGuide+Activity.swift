import UIKit
import Gridicons
import WordPressShared
import WordPressUI

/// This class groups all of the styles used by all of the ActivityListViewController.
///
extension WPStyleGuide {

    public struct ActivityStyleGuide {

        // MARK: - Public Properties

        public static let linkColor = UIAppColor.primary

        public static var contentRegularStyle: [NSAttributedString.Key: Any] {
            return  [
                .paragraphStyle: contentParagraph,
                .font: contentRegularFont,
                .foregroundColor: UIColor.label
            ]
        }

        public static var contentItalicStyle: [NSAttributedString.Key: Any] {
            return  [
                .paragraphStyle: contentParagraph,
                .font: contentItalicFont,
                .foregroundColor: UIColor.label
            ]
        }

        public static func backgroundColor() -> UIColor {
            return .secondarySystemGroupedBackground
        }
        
        @available(*, deprecated, message: "Use activity.gridiconType instead")
        public static func getGridiconTypeForActivity(_ activity: Activity) -> GridiconType? {
            return activity.gridiconType
        }

        @available(*, deprecated, message: "Use activity.icon instead")
        public static func getIconForActivity(_ activity: Activity) -> UIImage? {
            return activity.icon
        }

        @available(*, deprecated, message: "Use activity.statusColor instead")
        public static func getColorByActivityStatus(_ activity: Activity) -> UIColor {
            return activity.statusColor
        }

        // MARK: - Private Properties

        private static var minimumLineHeight: CGFloat {
            return contentFontSize * 1.3
        }

        private static let contentParagraph = NSMutableParagraphStyle(
            minLineHeight: minimumLineHeight, lineBreakMode: .byWordWrapping, alignment: .natural
        )

        private static var contentFontSize: CGFloat {
            return  UIFont.preferredFont(forTextStyle: .body).pointSize
        }

        private static var contentRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.body)
        }

        private static var contentItalicFont: UIFont {
            return  WPStyleGuide.fontForTextStyle(.body, symbolicTraits: .traitItalic)
        }
    }
}
