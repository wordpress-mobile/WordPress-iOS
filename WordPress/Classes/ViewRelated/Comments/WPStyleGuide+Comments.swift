import Foundation
import WordPressShared

/// This class groups all of the styles used by all of the CommentsViewController.
///
extension WPStyleGuide {
    public struct Comments {
        // MARK: - Public Properties
        //
        public static func gravatarPlaceholderImage(isApproved approved: Bool) -> UIImage {
            return approved ? gravatarApproved : gravatarUnapproved
        }

        public static func separatorsColor(isApproved approved: Bool) -> UIColor {
            return approved ? WPStyleGuide.readGrey() : WPStyleGuide.alertYellowDark()
        }

        public static func detailsRegularStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertYellowDark()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleRegularFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsRegularRedStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleRegularFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsItalicsStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleItalicsFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsBoldStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleBoldFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func timestampStyle(isApproved approved: Bool) -> [String: AnyObject] {
            let color = approved ? WPStyleGuide.allTAllShadeGrey() : WPStyleGuide.alertYellowDark()

            return  [   NSFontAttributeName: timestampFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func backgroundColor(isApproved approved: Bool) -> UIColor {
            return approved ? UIColor.white : WPStyleGuide.alertYellowLighter()
        }

        public static func timestampImage(isApproved approved: Bool) -> UIImage {
            let timestampImage = UIImage(named: "reader-postaction-time")!
            return approved ? timestampImage : timestampImage.withRenderingMode(.alwaysTemplate)
        }



        // MARK: - Private Properties
        //
        fileprivate static let gravatarApproved     = UIImage(named: "gravatar")!
        fileprivate static let gravatarUnapproved   = UIImage(named: "gravatar-unapproved")!

        private static var timestampFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.caption1)
        }

        private static var titleRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote)
        }

        private static var titleBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, fontWeight: UIFontWeightSemibold)
        }

        private static var titleItalicsFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitItalic)
        }

        private static var titleLineSize: CGFloat {
            return WPStyleGuide.fontSizeForTextStyle(.footnote) * 1.3
        }

        private static var titleParagraph: NSMutableParagraphStyle {
            return NSMutableParagraphStyle(minLineHeight: titleLineSize,
                                           maxLineHeight: titleLineSize,
                                           lineBreakMode: .byTruncatingTail,
                                           alignment: .natural)
        }
    }
}
