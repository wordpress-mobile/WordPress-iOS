import Foundation

import Gridicons
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    public struct Notifications {
        // MARK: - Styles Used by NotificationsViewController
        //

        // NoteTableViewHeader
        public static let sectionHeaderBackgroundColor  = UIColor(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 0xEA/255.0)

        public static var sectionHeaderRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: sectionHeaderParagraph,
                     .font: sectionHeaderFont,
                     .foregroundColor: sectionHeaderTextColor]
        }

        // NoteTableViewCell
        public static let noticonFont               = UIFont(name: "Noticons", size: 16)
        public static let noticonTextColor          = UIColor.white
        public static let noticonReadColor          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
        public static let noticonUnreadColor        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
        public static let noticonUnmoderatedColor   = WPStyleGuide.alertYellowDark()

        public static let noteBackgroundReadColor   = UIColor.white
        public static let noteBackgroundUnreadColor = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)

        public static let noteSeparatorColor        = blockSeparatorColor

        // NoteUndoOverlayView
        public static let noteUndoBackgroundColor   = WPStyleGuide.errorRed()
        public static let noteUndoTextColor         = UIColor.white
        public static let noteUndoTextFont          = subjectRegularFont

        // Subject Text
        public static var subjectRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: subjectParagraph,
                     .font: subjectRegularFont,
                     .foregroundColor: subjectTextColor ]
        }

        public static var subjectBoldStyle: [NSAttributedStringKey: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectBoldFont ]
        }

        public static var subjectItalicsStyle: [NSAttributedStringKey: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectItalicsFont ]
        }

        public static var subjectNoticonStyle: [NSAttributedStringKey: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectNoticonFont,
                    .foregroundColor: subjectNoticonColor ]
        }

        public static let subjectQuotedStyle = blockQuotedStyle

        // Subject Snippet
        public static var snippetRegularStyle: [NSAttributedStringKey: Any] {
            return [.paragraphStyle: snippetParagraph,
                    .font: subjectRegularFont,
                    .foregroundColor: snippetColor ]
        }

        // MARK: - Styles used by NotificationDetailsViewController
        //

        // Header
        public static let headerTitleColor          = blockTextColor
        public static let headerTitleBoldFont       = blockBoldFont

        public static let headerDetailsColor        = UIColor(red: 0x00/255.0, green: 0xAA/255.0, blue: 0xDC/255.0, alpha: 0xFF/255.0)
        public static let headerDetailsRegularFont  = blockRegularFont

        public static var headerTitleRegularStyle: [NSAttributedStringKey: Any] {
            return [.font: headerTitleRegularFont,
                    .foregroundColor: headerTitleColor]
        }

        public static var headerTitleBoldStyle: [NSAttributedStringKey: Any] {
            return  [.font: headerTitleBoldFont,
                     .foregroundColor: headerTitleColor]
        }

        public static var headerTitleContextStyle: [NSAttributedStringKey: Any] {
            return  [.font: headerTitleItalicsFont,
                     .foregroundColor: headerTitleContextColor]
        }

        // Footer
        public static var footerRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: footerTextColor]
        }

        // Badges
        public static let badgeBackgroundColor      = UIColor.clear
        public static let badgeLinkColor            = blockLinkColor

        public static let badgeRegularStyle: [NSAttributedStringKey: Any] = [.paragraphStyle: badgeParagraph,
                                                                             .font: blockRegularFont,
                                                                             .foregroundColor: blockTextColor]

        public static let badgeBoldStyle            = blockBoldStyle
        public static let badgeItalicsStyle         = blockItalicsStyle
        public static let badgeQuotedStyle          = blockQuotedStyle

        // Blocks
        public static let contentBlockRegularFont   = WPFontManager.notoRegularFont(ofSize: blockFontSize)
        public static let contentBlockBoldFont      = WPFontManager.notoBoldFont(ofSize: blockFontSize)
        public static let contentBlockItalicFont    = WPFontManager.notoItalicFont(ofSize: blockFontSize)
        public static let blockRegularFont          = WPFontManager.systemRegularFont(ofSize: blockFontSize)
        public static let blockBoldFont             = WPFontManager.systemSemiBoldFont(ofSize: blockFontSize)

        public static let blockTextColor            = WPStyleGuide.littleEddieGrey()
        public static let blockQuotedColor          = UIColor(red: 0x7E/255.0, green: 0x9E/255.0, blue: 0xB5/255.0, alpha: 0xFF/255.0)
        public static let blockBackgroundColor      = UIColor.white
        public static let blockLinkColor            = WPStyleGuide.baseLighterBlue()
        public static let blockSeparatorColor       = WPStyleGuide.readGrey()

        public static let blockApprovedBgColor      = UIColor.clear

        public static let blockUnapprovedSideColor  = WPStyleGuide.alertYellowDark()
        public static let blockUnapprovedBgColor    = WPStyleGuide.alertYellowLighter()
        public static let blockUnapprovedTextColor  = WPStyleGuide.alertRedDarker()
        public static let blockUnapprovedLinkColor  = WPStyleGuide.mediumBlue()

        public static var contentBlockRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockRegularFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockBoldStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockBoldFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockItalicStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockItalicFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockQuotedStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockItalicFont,
                     .foregroundColor: blockQuotedColor ]
        }

        public static var contentBlockMatchStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockRegularFont,
                     .foregroundColor: blockLinkColor ]
        }

        public static var blockRegularStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockBoldStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockBoldFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockItalicsStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockItalicsFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockQuotedStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockItalicsFont,
                     .foregroundColor: blockQuotedColor ]
        }

        public static var blockMatchStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: blockLinkColor ]
        }

        public static var blockNoticonStyle: [NSAttributedStringKey: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockNoticonFont,
                     .foregroundColor: blockNoticonColor ]
        }

        // Action Buttons
        public static let blockActionDisabledColor  = UIColor(red: 0x7F/255.0, green: 0x9E/255.0, blue: 0xB4/255.0, alpha: 0xFF/255.0)
        public static let blockActionEnabledColor   = UIColor(red: 0xEA/255.0, green: 0x6D/255.0, blue: 0x1B/255.0, alpha: 0xFF/255.0)

        // RichText Helpers
        public static func blockBackgroundColorForRichText(_ isBadge: Bool) -> UIColor {
            return isBadge ? badgeBackgroundColor : blockBackgroundColor
        }

        // Comment Helpers
        public static func blockGravatarPlaceholderImage(isApproved approved: Bool) -> UIImage {
            return approved ? .gravatarPlaceholderImage : .gravatarUnapprovedImage
        }

        public static func blockSeparatorColorForComment(isApproved approved: Bool) -> UIColor {
            return (approved ? blockSeparatorColor : blockUnapprovedSideColor)
        }

        public static func blockBackgroundColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockApprovedBgColor : blockUnapprovedBgColor
        }

        public static func blockTitleColorForComment(isApproved approved: Bool) -> UIColor {
            return (approved ? blockTextColor : blockUnapprovedTextColor)
        }

        public static func blockDetailsColorForComment(isApproved approved: Bool) -> UIColor {
            return approved ? blockQuotedColor : blockUnapprovedSideColor
        }

        public static func blockLinkColorForComment(isApproved approved: Bool) -> UIColor {
            return (approved ? blockLinkColor : blockUnapprovedLinkColor)
        }

        // Filters Helpers
        public static func configureSegmentedControl(_ segmentedControl: UISegmentedControl) {
            let style = [ NSAttributedStringKey.font: WPFontManager.systemRegularFont(ofSize: 12) ]
            segmentedControl.setTitleTextAttributes(style, for: UIControlState())
        }

        // User Cell Helpers
        public static func configureFollowButton(_ button: UIButton) {
            // General
            button.naturalContentHorizontalAlignment = .leading
            button.backgroundColor = .clear
            button.titleLabel?.font = WPStyleGuide.subtitleFont()

            // Color(s)
            let normalColor = WPStyleGuide.greyDarken20()
            let highlightedColor = WPStyleGuide.greyDarken10()
            let selectedColor = WPStyleGuide.validGreen()

            button.setTitleColor(normalColor, for: .normal)
            button.setTitleColor(selectedColor, for: .selected)
            button.setTitleColor(highlightedColor, for: .highlighted)

            // Image(s)
            let side = WPStyleGuide.fontSizeForTextStyle(.subheadline)
            let size = CGSize(width: side, height: side)
            let followIcon = Gridicon.iconOfType(.readerFollow, withSize: size)
            let followingIcon = Gridicon.iconOfType(.readerFollowing, withSize: size)

            button.setImage(followIcon.imageWithTintColor(normalColor), for: .normal)
            button.setImage(followingIcon.imageWithTintColor(selectedColor), for: .selected)
            button.setImage(followingIcon.imageWithTintColor(highlightedColor), for: .highlighted)
            button.imageEdgeInsets = UIEdgeInsets(top: 1, left: -4, bottom: 0, right: -4)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)

            // Strings
            let normalText = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
            let selectedText = NSLocalizedString("Following", comment: "User is following the blog.")

            button.setTitle(normalText, for: .normal)
            button.setTitle(selectedText, for: .selected)
            button.setTitle(selectedText, for: .highlighted)

            // Default accessibility label and hint.
            button.accessibilityLabel = normalText
            button.accessibilityHint = NSLocalizedString("Follows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a blog.")
        }


        // MARK: - Constants
        //

        public static let headerFontSize            = CGFloat(12)
        public static let headerLineSize            = CGFloat(16)
        public static let subjectFontSize           = UIDevice.isPad() ? CGFloat(16) : CGFloat(14)
        public static let subjectNoticonSize        = UIDevice.isPad() ? CGFloat(15) : CGFloat(14)
        public static let subjectLineSize           = UIDevice.isPad() ? CGFloat(24) : CGFloat(18)
        public static let snippetLineSize           = subjectLineSize
        public static let blockFontSize             = UIDevice.isPad() ? CGFloat(16) : CGFloat(14)
        public static let blockLineSize             = UIDevice.isPad() ? CGFloat(24) : CGFloat(20)
        public static let contentBlockLineSize      = UIDevice.isPad() ? CGFloat(24) : CGFloat(21)
        public static let maximumCellWidth          = CGFloat(600)


        // MARK: - Private Propreties
        //

        // ParagraphStyle's
        fileprivate static let sectionHeaderParagraph   = NSMutableParagraphStyle(
            minLineHeight: headerLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let subjectParagraph         = NSMutableParagraphStyle(
            minLineHeight: subjectLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let snippetParagraph         = NSMutableParagraphStyle(
            minLineHeight: snippetLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let blockParagraph           = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let contentBlockParagraph     = NSMutableParagraphStyle(
            minLineHeight: contentBlockLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let badgeParagraph           = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, maxLineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .center
        )

        // Colors
        fileprivate static let sectionHeaderTextColor   = UIColor(red: 0xA7/255.0, green: 0xBB/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
        fileprivate static let subjectTextColor         = WPStyleGuide.littleEddieGrey()
        fileprivate static let subjectNoticonColor      = noticonReadColor
        fileprivate static let footerTextColor          = WPStyleGuide.allTAllShadeGrey()
        fileprivate static let blockNoticonColor        = WPStyleGuide.allTAllShadeGrey()
        fileprivate static let snippetColor             = WPStyleGuide.allTAllShadeGrey()
        fileprivate static let headerTitleContextColor  = WPStyleGuide.allTAllShadeGrey()

        // Fonts
        fileprivate static var sectionHeaderFont: UIFont {
            if #available(iOS 11.0, *) {
                return WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .semibold)
            } else {
                return WPFontManager.systemSemiBoldFont(ofSize: headerFontSize)
            }
        }
        fileprivate static var subjectRegularFont: UIFont {
            if #available(iOS 11.0, *) {
                return WPStyleGuide.fontForTextStyle(.subheadline)
            } else {
                return WPFontManager.systemRegularFont(ofSize: subjectFontSize)
            }
        }
        fileprivate static var subjectBoldFont: UIFont {
            if #available(iOS 11.0, *) {
                return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .bold)
            } else {
                return WPFontManager.systemSemiBoldFont(ofSize: subjectFontSize)
            }
        }
        fileprivate static var subjectItalicsFont: UIFont {
            if #available(iOS 11.0, *) {
                return  WPStyleGuide.fontForTextStyle(.subheadline, symbolicTraits: .traitItalic)
            } else {
                return WPFontManager.systemItalicFont(ofSize: subjectFontSize)
            }
        }

        fileprivate static let subjectNoticonFont       = UIFont(name: "Noticons", size: subjectNoticonSize)!
        fileprivate static let headerTitleRegularFont   = blockRegularFont
        fileprivate static let headerTitleItalicsFont   = blockItalicsFont
        fileprivate static let blockItalicsFont         = WPFontManager.systemItalicFont(ofSize: blockFontSize)
        fileprivate static let blockNoticonFont         = subjectNoticonFont
    }
}
