import Foundation

import Gridicons
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    public struct Notifications {
        // MARK: - Styles Used by NotificationsViewController
        //

        // NoteTableViewHeader
        public static let sectionHeaderBackgroundColor = UIColor.listBackground

        public static var sectionHeaderRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: sectionHeaderParagraph,
                     .font: sectionHeaderFont,
                     .foregroundColor: sectionHeaderTextColor]
        }

        // NoteTableViewCell
        public static let noticonFont               = UIFont(name: "Noticons", size: 16)
        public static let noticonTextColor          = UIColor.textInverted
        public static let noticonReadColor          = UIColor.listSmallIcon
        public static let noticonUnreadColor        = UIColor.primary
        public static let noticonUnmoderatedColor   = UIColor.warning

        public static let noteBackgroundReadColor   = UIColor.listForeground
        public static let noteBackgroundUnreadColor = UIColor.listForegroundUnread

        public static let noteSeparatorColor        = blockSeparatorColor

        // NoteUndoOverlayView
        public static let noteUndoBackgroundColor   = UIColor.error
        public static let noteUndoTextColor         = UIColor.white
        public static let noteUndoTextFont          = subjectRegularFont

        // Subject Text
        public static var subjectRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: subjectParagraph,
                     .font: subjectRegularFont,
                     .foregroundColor: subjectTextColor ]
        }

        public static var subjectBoldStyle: [NSAttributedString.Key: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectBoldFont ]
        }

        public static var subjectItalicsStyle: [NSAttributedString.Key: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectItalicsFont ]
        }

        public static var subjectNoticonStyle: [NSAttributedString.Key: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectNoticonFont,
                    .foregroundColor: subjectNoticonColor ]
        }

        public static let subjectQuotedStyle = blockQuotedStyle

        // Subject Snippet
        public static var snippetRegularStyle: [NSAttributedString.Key: Any] {
            return [.paragraphStyle: snippetParagraph,
                    .font: subjectRegularFont,
                    .foregroundColor: snippetColor ]
        }

        // MARK: - Styles used by NotificationDetailsViewController
        //

        // Header
        public static let headerTitleColor          = blockTextColor
        public static let headerTitleBoldFont       = blockBoldFont

        public static let headerDetailsColor        = UIColor.primary
        public static let headerDetailsRegularFont  = blockRegularFont

        public static var headerTitleRegularStyle: [NSAttributedString.Key: Any] {
            return [.font: headerTitleRegularFont,
                    .foregroundColor: headerTitleColor]
        }

        public static var headerTitleBoldStyle: [NSAttributedString.Key: Any] {
            return  [.font: headerTitleBoldFont,
                     .foregroundColor: headerTitleColor]
        }

        public static var headerTitleContextStyle: [NSAttributedString.Key: Any] {
            return  [.font: headerTitleItalicsFont,
                     .foregroundColor: headerTitleContextColor]
        }

        // Footer
        public static var footerRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: footerTextColor]
        }

        // Badges
        public static let badgeBackgroundColor      = UIColor.clear
        public static let badgeLinkColor            = blockLinkColor

        public static let badgeRegularStyle: [NSAttributedString.Key: Any] = [.paragraphStyle: badgeParagraph,
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

        public static let blockTextColor            = UIColor.text
        public static let blockQuotedColor          = UIColor.neutral
        public static let blockBackgroundColor      = UIColor.listForeground
        public static let blockLinkColor            = UIColor.primary
        public static let blockSeparatorColor       = UIColor.divider

        public static let blockApprovedBgColor      = UIColor.clear

        public static let blockUnapprovedSideColor  = UIColor.warning(.shade60)
        public static let blockUnapprovedBgColor    = UIColor(light: .warning(.shade0), dark: .warning(.shade90))
        public static let blockUnapprovedTextColor  = UIColor.text
        public static let blockUnapprovedLinkColor  = UIColor.primary

        public static var contentBlockRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockRegularFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockBoldStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockBoldFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockItalicStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockItalicFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var contentBlockQuotedStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockItalicFont,
                     .foregroundColor: blockQuotedColor ]
        }

        public static var contentBlockMatchStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: contentBlockParagraph,
                     .font: contentBlockRegularFont,
                     .foregroundColor: blockLinkColor ]
        }

        public static var blockRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockBoldStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockBoldFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockItalicsStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockItalicsFont,
                     .foregroundColor: blockTextColor ]
        }

        public static var blockQuotedStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockItalicsFont,
                     .foregroundColor: blockQuotedColor ]
        }

        public static var blockMatchStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockRegularFont,
                     .foregroundColor: blockLinkColor ]
        }

        public static var blockNoticonStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockNoticonFont,
                     .foregroundColor: blockNoticonColor ]
        }

        // Action Buttons
        public static let blockActionDisabledColor  = UIColor.listIcon
        public static let blockActionEnabledColor   = UIColor.primary

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
            let style = [ NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 12) ]
            segmentedControl.setTitleTextAttributes(style, for: UIControl.State())
        }

        // User Cell Helpers
        public static func configureFollowButton(_ button: UIButton) {
            // General
            button.naturalContentHorizontalAlignment = .leading
            button.backgroundColor = .clear
            button.titleLabel?.font = WPStyleGuide.subtitleFont()

            // Color(s)
            let normalColor = UIColor.neutral(.shade50)
            let highlightedColor = UIColor.neutral(.shade40)
            let selectedColor = UIColor.success

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
        fileprivate static let sectionHeaderTextColor   = UIColor.textSubtle
        fileprivate static let subjectTextColor         = UIColor.text
        fileprivate static let subjectNoticonColor      = noticonReadColor
        fileprivate static let footerTextColor          = UIColor.textSubtle
        fileprivate static let blockNoticonColor        = UIColor.neutral
        fileprivate static let snippetColor             = UIColor.neutral
        fileprivate static let headerTitleContextColor  = UIColor.primary

        // Fonts
        fileprivate static var sectionHeaderFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .semibold)
        }
        fileprivate static var subjectRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.subheadline)
        }
        fileprivate static var subjectBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .bold)
        }
        fileprivate static var subjectItalicsFont: UIFont {
            return  WPStyleGuide.fontForTextStyle(.subheadline, symbolicTraits: .traitItalic)
        }

        fileprivate static let subjectNoticonFont       = UIFont(name: "Noticons", size: subjectNoticonSize)!
        fileprivate static let headerTitleRegularFont   = blockRegularFont
        fileprivate static let headerTitleItalicsFont   = blockItalicsFont
        fileprivate static let blockItalicsFont         = WPFontManager.systemItalicFont(ofSize: blockFontSize)
        fileprivate static let blockNoticonFont         = subjectNoticonFont
    }
}
