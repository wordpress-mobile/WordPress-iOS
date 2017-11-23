import Foundation
import Gridicons
import WordPressShared

/// This class groups all of the styles used by all of the ActivityListViewController.
///
extension WPStyleGuide {

    public struct ActivityStyleGuide {

        // MARK: - Public Properties

        public static func gravatarPlaceholderImage() -> UIImage {
            return gravatar
        }

        public static func summaryRegularStyle() -> [String: AnyObject] {
            return  [NSParagraphStyleAttributeName: summaryParagraph,
                     NSFontAttributeName: summaryRegularFont,
                     NSForegroundColorAttributeName: WPStyleGuide.littleEddieGrey()]
        }

        public static func summaryBoldStyle() -> [String: AnyObject] {
            return [NSParagraphStyleAttributeName: summaryParagraph,
                    NSFontAttributeName: summaryBoldFont,
                    NSForegroundColorAttributeName: WPStyleGuide.littleEddieGrey()]
        }

        public static func timestampStyle() -> [String: AnyObject] {
            return  [NSFontAttributeName: timestampFont,
                     NSForegroundColorAttributeName: WPStyleGuide.allTAllShadeGrey()]
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

        public static func getIconForActivity(_ activity: Activity) -> UIImage? {
            if let gridicon = stringToGridiconMapping[activity.gridicon] {
                return gridicon.imageWithTintColor(getColorByActivityStatus(activity))
            }
            return nil
        }

        // MARK: - Private Properties

        fileprivate static let gravatar = UIImage(named: "gravatar")!

        private static var timestampFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.caption1)
        }

        private static var summaryRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote)
        }

        private static var summaryBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, fontWeight: UIFontWeightSemibold)
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

        private static func getColorByActivityStatus(_ activity: Activity) -> UIColor {
            if activity.isStatusError {
                return WPStyleGuide.errorRed()
            }
            if activity.isStatusSuccess {
                return WPStyleGuide.validGreen()
            }
            if activity.isStatusWarning {
                return WPStyleGuide.warningYellow()
            }
            return WPStyleGuide.greyLighten10()
        }

        // We will be able to get rid of this disgusting dictionary once we build the
        // String->Gridicon mapping into the Gridicon module and we get a server side
        // fix to have all the names correctly mapping.
        private static let stringToGridiconMapping: [String: UIImage] = [
            "checkmark": Gridicon.iconOfType(.checkmark),
            "cog": Gridicon.iconOfType(.cog),
            "comment": Gridicon.iconOfType(.comment),
            "cross": Gridicon.iconOfType(.cross),
            "domains": Gridicon.iconOfType(.domains),
            "history": Gridicon.iconOfType(.history),
            "image": Gridicon.iconOfType(.image),
            "layout": Gridicon.iconOfType(.layout),
            "lock": Gridicon.iconOfType(.lock),
            "logout": Gridicon.iconOfType(.signOut),
            "mail": Gridicon.iconOfType(.mail),
            "menu": Gridicon.iconOfType(.menu),
            "my-sites": Gridicon.iconOfType(.mySites),
            "notice": Gridicon.iconOfType(.notice),
            "notice-outline": Gridicon.iconOfType(.noticeOutline),
            "pages": Gridicon.iconOfType(.pages),
            "plugins": Gridicon.iconOfType(.plugins),
            "posts": Gridicon.iconOfType(.posts),
            "share": Gridicon.iconOfType(.share),
            "shipping": Gridicon.iconOfType(.shipping),
            "spam": Gridicon.iconOfType(.spam),
            "themes": Gridicon.iconOfType(.themes),
            "trash": Gridicon.iconOfType(.trash),
            "user": Gridicon.iconOfType(.user),
        ]
    }
}
