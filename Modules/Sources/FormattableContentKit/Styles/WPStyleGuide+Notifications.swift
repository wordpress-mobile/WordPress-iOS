// FIXME: This does not belong here, see https://github.com/wordpress-mobile/WordPress-iOS/pull/24297
import Foundation
import Gridicons
import UIKit
import WordPressShared
import WordPressKit // FIXME: Here just for the NSMutableParagraphStyle custom init
import WordPressUI

extension WPStyleGuide {
    public struct Notifications {
        // MARK: - Styles Used by NotificationsViewController
        //

        // ListTableViewCell
        public static let unreadIndicatorColor = UIAppColor.primaryLight

        // Notification cells
        public static let noticonFont = UIFont(name: "Noticons", size: 16)
        public static let noticonReadColor = UIColor.systemGray

        // Notification undo overlay
        public static let noteUndoBackgroundColor = UIAppColor.error
        public static let noteUndoTextColor = UIColor.white
        public static let noteUndoTextFont = subjectRegularFont

        // Subject Text
        public static var subjectRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: subjectParagraph,
                     .font: subjectRegularFont,
                     .foregroundColor: subjectTextColor ]
        }

        public static var subjectSemiBoldStyle: [NSAttributedString.Key: Any] {
            return [.paragraphStyle: subjectParagraph,
                    .font: subjectSemiBoldFont ]
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

        public static var headerDetailsRegularStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: snippetHeaderParagraph,
                     .font: headerDetailsRegularFont,
                     .foregroundColor: headerDetailsColor
            ]
        }

        // MARK: - Styles used by NotificationDetailsViewController
        //

        // Header
        public static let headerTitleColor = blockTextColor
        public static let headerTitleBoldFont = blockBoldFont

        public static let headerDetailsColor = UIAppColor.primary
        public static let headerDetailsRegularFont = blockRegularFont

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
        public static let badgeBackgroundColor = UIColor.clear
        public static let badgeLinkColor = blockLinkColor
        public static let badgeTextColor = blockTextColor
        public static let badgeQuotedColor = blockQuotedColor

        public static let badgeRegularFont = UIFont.preferredFont(forTextStyle: .body)
        public static let badgeBoldFont = badgeRegularFont.semibold()
        public static let badgeItalicsFont = badgeRegularFont.italic()

        public static let badgeTitleFont = WPStyleGuide.serifFontForTextStyle(.title1)
        public static let badgeTitleBoldFont = badgeTitleFont.semibold()
        public static let badgeTitleItalicsFont = badgeTitleFont.italic()

        public static var badgeRegularStyle: [NSAttributedString.Key: Any] {
            badgeStyle(withFont: badgeRegularFont)
        }

        public static var badgeBoldStyle: [NSAttributedString.Key: Any] {
            badgeStyle(withFont: badgeBoldFont)
        }

        public static var badgeItalicsStyle: [NSAttributedString.Key: Any] {
            badgeStyle(withFont: badgeItalicsFont)
        }

        public static var badgeQuotedStyle: [NSAttributedString.Key: Any] {
            badgeStyle(withFont: badgeItalicsFont, color: badgeQuotedColor)
        }

        public static let badgeTitleStyle: [NSAttributedString.Key: Any] = badgeStyle(withFont: badgeTitleFont)
        public static var badgeTitleBoldStyle: [NSAttributedString.Key: Any] = badgeStyle(withFont: badgeTitleBoldFont)
        public static var badgeTitleItalicsStyle: [NSAttributedString.Key: Any] = badgeStyle(withFont: badgeTitleItalicsFont)
        public static var badgeTitleQuotedStyle: [NSAttributedString.Key: Any] = badgeStyle(withFont: badgeTitleItalicsFont, color: badgeQuotedColor)

        private static func badgeStyle(withFont font: UIFont, color: UIColor = badgeTextColor) -> [NSAttributedString.Key: Any] {
            return [.paragraphStyle: badgeParagraph, .font: font, .foregroundColor: color ]
        }

        // Blocks
        public static let contentBlockRegularFont = WPFontManager.notoRegularFont(ofSize: blockFontSize)
        public static let contentBlockBoldFont = WPFontManager.notoBoldFont(ofSize: blockFontSize)
        public static let contentBlockItalicFont = WPFontManager.notoItalicFont(ofSize: blockFontSize)
        public static let blockRegularFont = WPFontManager.systemRegularFont(ofSize: blockFontSize)
        public static let blockBoldFont = WPFontManager.systemSemiBoldFont(ofSize: blockFontSize)

        public static let blockTextColor = UIColor.label
        public static let blockQuotedColor = UIAppColor.neutral
        public static let blockBackgroundColor = UIColor.secondarySystemGroupedBackground
        public static let blockLinkColor = UIAppColor.primary
        public static let blockSeparatorColor = UIColor.separator

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

        public static var blockQuotedStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockItalicsFont,
                     .foregroundColor: blockQuotedColor ]
        }

        public static var blockNoticonStyle: [NSAttributedString.Key: Any] {
            return  [.paragraphStyle: blockParagraph,
                     .font: blockNoticonFont,
                     .foregroundColor: blockNoticonColor ]
        }

        // RichText Helpers
        public static func blockBackgroundColorForRichText(_ isBadge: Bool) -> UIColor {
            return isBadge ? badgeBackgroundColor : blockBackgroundColor
        }

        // User Cell Helpers
        public static func configureFollowButton(_ button: UIButton) {
            // General
            button.naturalContentHorizontalAlignment = .leading
            button.backgroundColor = .clear
            button.titleLabel?.font = WPStyleGuide.subtitleFont()

            // Color(s)
            let normalColor = UIAppColor.neutral(.shade50)
            let highlightedColor = UIAppColor.neutral(.shade40)
            let selectedColor = UIAppColor.success

            button.setTitleColor(normalColor, for: .normal)
            button.setTitleColor(selectedColor, for: .selected)
            button.setTitleColor(highlightedColor, for: .highlighted)

            // Image(s)
            let side = WPStyleGuide.fontSizeForTextStyle(.subheadline)
            let size = CGSize(width: side, height: side)
            let followIcon = UIImage.gridicon(.readerFollow, size: size)
            let followingIcon = UIImage.gridicon(.readerFollowing, size: size)

            button.setImage(followIcon.imageWithTintColor(normalColor), for: .normal)
            button.setImage(followingIcon.imageWithTintColor(selectedColor), for: .selected)
            button.setImage(followingIcon.imageWithTintColor(highlightedColor), for: .highlighted)
            button.imageEdgeInsets = UIEdgeInsets(top: 1, left: -4, bottom: 0, right: -4)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)

            // Strings
            let normalText = NSLocalizedString("notifications.button.subscribe", value: "Subscribe", comment: "Prompt to subscribe to a blog.")
            let selectedText = NSLocalizedString("notifications.button.subscribed", value: "Subscribed", comment: "User is subscribed to the blog.")

            button.setTitle(normalText, for: .normal)
            button.setTitle(selectedText, for: .selected)
            button.setTitle(selectedText, for: .highlighted)

            // Default accessibility label and hint.
            button.accessibilityLabel = normalText
            button.accessibilityHint = NSLocalizedString("notifications.button.subscribedHint", value: "Subscribes to the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to subscribe to a blog.")
        }

        // MARK: - Constants
        //

        public static let subjectNoticonSize = UIDevice.isPad() ? CGFloat(15) : CGFloat(14)
        public static let subjectLineSize = UIDevice.isPad() ? CGFloat(24) : CGFloat(18)
        public static let snippetLineSize = subjectLineSize
        public static let blockFontSize = UIDevice.isPad() ? CGFloat(16) : CGFloat(14)
        public static let blockLineSize = UIDevice.isPad() ? CGFloat(24) : CGFloat(20)
        public static let contentBlockLineSize = UIDevice.isPad() ? CGFloat(24) : CGFloat(21)

        // MARK: - Private Propreties
        //

        // ParagraphStyle's
        fileprivate static let subjectParagraph = NSMutableParagraphStyle(
            minLineHeight: subjectLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let snippetParagraph = NSMutableParagraphStyle(
            minLineHeight: snippetLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let snippetHeaderParagraph = NSMutableParagraphStyle(
            minLineHeight: snippetLineSize, lineBreakMode: .byTruncatingTail, alignment: .natural
        )
        fileprivate static let blockParagraph = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let contentBlockParagraph = NSMutableParagraphStyle(
            minLineHeight: contentBlockLineSize, lineBreakMode: .byWordWrapping, alignment: .natural
        )
        fileprivate static let badgeParagraph = NSMutableParagraphStyle(
            minLineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .center
        )

        // Colors
        fileprivate static let subjectTextColor = UIColor.label
        fileprivate static let subjectNoticonColor = noticonReadColor
        fileprivate static let footerTextColor = UIColor.secondaryLabel
        fileprivate static let blockNoticonColor = UIAppColor.neutral
        fileprivate static let snippetColor = UIAppColor.neutral
        fileprivate static let headerTitleContextColor = UIAppColor.primary

        // Fonts
        fileprivate static var subjectRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.subheadline)
        }
        fileprivate static var subjectSemiBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        }
        fileprivate static var subjectItalicsFont: UIFont {
            return  WPStyleGuide.fontForTextStyle(.subheadline, symbolicTraits: .traitItalic)
        }

        fileprivate static let subjectNoticonFont = UIFont(name: "Noticons", size: subjectNoticonSize)!
        fileprivate static let headerTitleRegularFont = blockRegularFont
        fileprivate static let headerTitleItalicsFont = blockItalicsFont
        fileprivate static let blockItalicsFont = WPFontManager.systemItalicFont(ofSize: blockFontSize)
        fileprivate static let blockNoticonFont = subjectNoticonFont
    }
}

// FIXME: Duplicated move to appropriate location
extension UIFont {
    /// Returns a UIFont instance with the italic trait applied.
    func italic() -> UIFont {
        return withSymbolicTraits(.traitItalic)
    }

    /// Returns a UIFont instance with the semibold trait applied.
    func semibold() -> UIFont {
        return withWeight(.semibold)
    }

    private func withSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
