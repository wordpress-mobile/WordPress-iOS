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

        public static func detailsRegularStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertYellowDark()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleRegularFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsRegularRedStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleRegularFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsItalicsStyle(isApproved approved: Bool) -> [String : AnyObject] {
            let color = approved ? WPStyleGuide.littleEddieGrey() : WPStyleGuide.alertRedDarker()

            return  [   NSParagraphStyleAttributeName: titleParagraph,
                        NSFontAttributeName: titleItalicsFont,
                        NSForegroundColorAttributeName: color ]
        }

        public static func detailsBoldStyle(isApproved approved: Bool) -> [String : AnyObject] {
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

        fileprivate static let timestampFont        = WPStyleGuide.subtitleFont()

        fileprivate static let titleFontSize        = CGFloat(14)
        fileprivate static let titleRegularFont     = WPFontManager.systemRegularFont(ofSize: titleFontSize)
        fileprivate static let titleBoldFont        = WPFontManager.systemSemiBoldFont(ofSize: titleFontSize)
        fileprivate static let titleItalicsFont     = WPFontManager.systemItalicFont(ofSize: titleFontSize)

        fileprivate static let titleLineSize        = CGFloat(18)
        fileprivate static let titleParagraph       = NSMutableParagraphStyle(minLineHeight: titleLineSize,
                                                    maxLineHeight:  titleLineSize,
                                                    lineBreakMode:  .byTruncatingTail,
                                                    alignment:      .natural)
    }
}
