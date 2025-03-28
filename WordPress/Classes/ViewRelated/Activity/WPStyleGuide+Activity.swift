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

        public static func getGridiconTypeForActivity(_ activity: Activity) -> GridiconType? {
            return stringToGridiconTypeMapping[activity.gridicon]
        }

        public static func getIconForActivity(_ activity: Activity) -> UIImage? {
            guard let gridiconType = stringToGridiconTypeMapping[activity.gridicon] else {
                return nil
            }

            return UIImage.gridicon(gridiconType).imageWithTintColor(.white)
        }

        public static func getColorByActivityStatus(_ activity: Activity) -> UIColor {
            switch activity.status {
            case ActivityStatus.error:
                return UIAppColor.error
            case ActivityStatus.success:
                return UIAppColor.success
            case ActivityStatus.warning:
                return UIAppColor.warning
            default:
                return UIAppColor.neutral(.shade20)
            }
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

        // We will be able to get rid of this disgusting dictionary once we build the
        // String->GridiconType mapping into the Gridicon module and we get a server side
        // fix to have all the names correctly mapping.
        private static let stringToGridiconTypeMapping: [String: GridiconType] = [
            "checkmark": GridiconType.checkmark,
            "cloud": GridiconType.cloud,
            "cog": GridiconType.cog,
            "comment": GridiconType.comment,
            "cross": GridiconType.cross,
            "domains": GridiconType.domains,
            "history": GridiconType.history,
            "image": GridiconType.image,
            "layout": GridiconType.layout,
            "lock": GridiconType.lock,
            "logout": GridiconType.signOut,
            "mail": GridiconType.mail,
            "menu": GridiconType.menu,
            "my-sites": GridiconType.mySites,
            "notice": GridiconType.notice,
            "notice-outline": GridiconType.noticeOutline,
            "pages": GridiconType.pages,
            "plans": GridiconType.plans,
            "plugins": GridiconType.plugins,
            "posts": GridiconType.posts,
            "share": GridiconType.share,
            "shipping": GridiconType.shipping,
            "spam": GridiconType.spam,
            "themes": GridiconType.themes,
            "trash": GridiconType.trash,
            "user": GridiconType.user,
            "video": GridiconType.video,
            "status": GridiconType.status,
            "cart": GridiconType.cart,
            "custom-post-type": GridiconType.customPostType,
            "multiple-users": GridiconType.multipleUsers,
            "audio": GridiconType.audio
        ]
    }
}
