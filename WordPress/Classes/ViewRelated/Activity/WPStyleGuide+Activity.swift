import Foundation
import Gridicons
import WordPressShared

/// This class groups all of the styles used by all of the ActivityListViewController.
///
extension WPStyleGuide {

    public struct ActivityStyleGuide {

        // MARK: - Public Properties

        public static let linkColor = WPStyleGuide.baseLighterBlue()

        public static var contentRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentParagraph,
                     .font: contentRegularFont,
                     .foregroundColor: contentTextColor ]
        }

        public static var contentItalicStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentParagraph,
                     .font: contentItalicFont,
                     .foregroundColor: contentTextColor ]
        }

        public static func gravatarPlaceholderImage() -> UIImage {
            return gravatar
        }

        public static func summaryRegularStyle() -> [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: summaryParagraph,
                     .font: summaryRegularFont,
                     .foregroundColor: WPStyleGuide.littleEddieGrey()]
        }

        public static func summaryBoldStyle() -> [NSAttributedStringKey: Any] {
            return [.paragraphStyle: summaryParagraph,
                    .font: summaryBoldFont,
                    .foregroundColor: WPStyleGuide.littleEddieGrey()]
        }

        public static func timestampStyle() -> [NSAttributedStringKey: Any] {
            return  [.font: timestampFont,
                     .foregroundColor: WPStyleGuide.allTAllShadeGrey()]
        }

        public static func backgroundColor() -> UIColor {
            return UIColor.white
        }

        public static func backgroundDiscardedColor() -> UIColor {
            return WPStyleGuide.greyLighten30()
        }

        public static func backgroundRewindableColor() -> UIColor {
            return WPStyleGuide.lightBlue()
        }

        public static func getGridiconTypeForActivity(_ activity: Activity) -> GridiconType? {
            return stringToGridiconTypeMapping[activity.gridicon]
        }

        public static func getIconForActivity(_ activity: Activity) -> UIImage? {
            guard let gridiconType = stringToGridiconTypeMapping[activity.gridicon] else {
                return nil
            }

            return Gridicon.iconOfType(gridiconType).imageWithTintColor(.white)
        }

        public static func getColorByActivityStatus(_ activity: Activity) -> UIColor {
            switch activity.status {
            case ActivityStatus.error:
                return WPStyleGuide.errorRed()
            case ActivityStatus.success:
                return WPStyleGuide.validGreen()
            case ActivityStatus.warning:
                return WPStyleGuide.warningYellow()
            default:
                return WPStyleGuide.greyLighten10()
            }
        }

        // MARK: - Private Properties

        private static let contentTextColor = WPStyleGuide.littleEddieGrey()

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
            if #available(iOS 11.0, *) {
                return WPStyleGuide.fontForTextStyle(.body)

            } else {
                return WPFontManager.systemRegularFont(ofSize: contentFontSize)
            }
        }

        private static var contentItalicFont: UIFont {
            if #available(iOS 11.0, *) {
                return  WPStyleGuide.fontForTextStyle(.body, symbolicTraits: .traitItalic)
            } else {
                return WPFontManager.systemItalicFont(ofSize: contentFontSize)
            }
        }

        fileprivate static let gravatar = UIImage(named: "gravatar")!

        private static var timestampFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.caption1)
        }

        private static var summaryRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote)
        }

        private static var summaryBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        }

        private static var summaryLineSize: CGFloat {
            return WPStyleGuide.fontSizeForTextStyle(.footnote) * 1.3
        }

        private static var summaryParagraph: NSMutableParagraphStyle {
            return NSMutableParagraphStyle(minLineHeight: summaryLineSize,
                                           maxLineHeight: summaryLineSize,
                                           lineBreakMode: .byTruncatingTail,
                                           alignment: .natural)
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
        ]
    }
}
