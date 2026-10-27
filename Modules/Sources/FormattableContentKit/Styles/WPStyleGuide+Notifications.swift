// FIXME: This does not belong here, see https://github.com/wordpress-mobile/WordPress-iOS/pull/24297
import Foundation
import Gridicons
import UIKit
import WordPressShared
import WordPressSharedUI
import WordPressKit // FIXME: Here just for the NSMutableParagraphStyle custom init
import WordPressUI

extension WPStyleGuide {
    public struct Notifications {
        /// Text attributes for a notification style.
        public typealias Attributes = [NSAttributedString.Key: Any]

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
        public static func subjectRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: subjectParagraph(for: sizeClass),
                     .font: subjectRegularFont,
                     .foregroundColor: subjectTextColor ]
        }

        public static func subjectSemiBoldStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return [.paragraphStyle: subjectParagraph(for: sizeClass),
                    .font: subjectSemiBoldFont ]
        }

        public static func subjectItalicsStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return [.paragraphStyle: subjectParagraph(for: sizeClass),
                    .font: subjectItalicsFont ]
        }

        public static func subjectNoticonStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return [.paragraphStyle: subjectParagraph(for: sizeClass),
                    .font: subjectNoticonFont(for: sizeClass),
                    .foregroundColor: subjectNoticonColor ]
        }

        public static func subjectQuotedStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            blockQuotedStyle(for: sizeClass)
        }

        // Subject Snippet
        public static func snippetRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return [.paragraphStyle: snippetParagraph(for: sizeClass),
                    .font: subjectRegularFont,
                    .foregroundColor: snippetColor ]
        }

        public static func headerDetailsRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: snippetHeaderParagraph(for: sizeClass),
                     .font: headerDetailsRegularFont(for: sizeClass),
                     .foregroundColor: headerDetailsColor
            ]
        }

        // MARK: - Styles used by NotificationDetailsViewController
        //

        // Header
        public static let headerTitleColor = blockTextColor
        public static func headerTitleBoldFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            blockBoldFont(for: sizeClass)
        }

        public static let headerDetailsColor = UIAppColor.primary
        public static func headerDetailsRegularFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            blockRegularFont(for: sizeClass)
        }

        public static func headerTitleRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return [.font: headerTitleRegularFont(for: sizeClass),
                    .foregroundColor: headerTitleColor]
        }

        public static func headerTitleBoldStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.font: headerTitleBoldFont(for: sizeClass),
                     .foregroundColor: headerTitleColor]
        }

        public static func headerTitleContextStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.font: headerTitleItalicsFont(for: sizeClass),
                     .foregroundColor: headerTitleContextColor]
        }

        // Footer
        public static func footerRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: blockParagraph(for: sizeClass),
                     .font: blockRegularFont(for: sizeClass),
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

        public static func badgeRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeRegularFont, for: sizeClass)
        }

        public static func badgeBoldStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeBoldFont, for: sizeClass)
        }

        public static func badgeItalicsStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeItalicsFont, for: sizeClass)
        }

        public static func badgeQuotedStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeItalicsFont, color: badgeQuotedColor, for: sizeClass)
        }

        public static func badgeTitleStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeTitleFont, for: sizeClass)
        }

        public static func badgeTitleBoldStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeTitleBoldFont, for: sizeClass)
        }

        public static func badgeTitleItalicsStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeTitleItalicsFont, for: sizeClass)
        }

        public static func badgeTitleQuotedStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            badgeStyle(withFont: badgeTitleItalicsFont, color: badgeQuotedColor, for: sizeClass)
        }

        private static func badgeStyle(
            withFont font: UIFont,
            color: UIColor = badgeTextColor,
            for sizeClass: UIUserInterfaceSizeClass
        ) -> Attributes {
            return [.paragraphStyle: badgeParagraph(for: sizeClass), .font: font, .foregroundColor: color ]
        }

        // Blocks
        public static func contentBlockRegularFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).contentBlockRegularFont
        }

        public static func contentBlockBoldFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).contentBlockBoldFont
        }

        public static func contentBlockItalicFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).contentBlockItalicFont
        }

        public static func blockRegularFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).blockRegularFont
        }

        public static func blockBoldFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).blockBoldFont
        }

        public static let blockTextColor = UIColor.label
        public static let blockQuotedColor = UIAppColor.neutral
        public static let blockBackgroundColor = UIColor.secondarySystemGroupedBackground
        public static let blockLinkColor = UIAppColor.primary
        public static let blockSeparatorColor = UIColor.separator

        public static func contentBlockRegularStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: contentBlockParagraph(for: sizeClass),
                     .font: contentBlockRegularFont(for: sizeClass),
                     .foregroundColor: blockTextColor ]
        }

        public static func contentBlockBoldStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: contentBlockParagraph(for: sizeClass),
                     .font: contentBlockBoldFont(for: sizeClass),
                     .foregroundColor: blockTextColor ]
        }

        public static func contentBlockQuotedStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: contentBlockParagraph(for: sizeClass),
                     .font: contentBlockItalicFont(for: sizeClass),
                     .foregroundColor: blockQuotedColor ]
        }

        public static func contentBlockMatchStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: contentBlockParagraph(for: sizeClass),
                     .font: contentBlockRegularFont(for: sizeClass),
                     .foregroundColor: blockLinkColor ]
        }

        public static func blockQuotedStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: blockParagraph(for: sizeClass),
                     .font: blockItalicsFont(for: sizeClass),
                     .foregroundColor: blockQuotedColor ]
        }

        public static func blockNoticonStyle(for sizeClass: UIUserInterfaceSizeClass) -> Attributes {
            return  [.paragraphStyle: blockParagraph(for: sizeClass),
                     .font: blockNoticonFont(for: sizeClass),
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

            // Color(s)
            let normalColor = UIAppColor.neutral(.shade50)
            let highlightedColor = UIAppColor.neutral(.shade40)
            let selectedColor = UIAppColor.success

            // Image(s)
            let side = WPStyleGuide.fontSizeForTextStyle(.subheadline)
            let size = CGSize(width: side, height: side)
            let followIcon = UIImage.gridicon(.readerFollow, size: size)
            let followingIcon = UIImage.gridicon(.readerFollowing, size: size)

            // Strings
            let normalText = NSLocalizedString("notifications.button.subscribe", value: "Subscribe", comment: "Prompt to subscribe to a blog.")
            let selectedText = NSLocalizedString("notifications.button.subscribed", value: "Subscribed", comment: "User is subscribed to the blog.")

            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            configuration.imagePadding = followButtonImagePadding
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = WPStyleGuide.subtitleFont()
                return attributes
            }
            button.configuration = configuration

            button.configurationUpdateHandler = { button in
                var configuration = button.configuration

                // A plain configuration tints the background of a selected button.
                var background = UIBackgroundConfiguration.clear()
                background.backgroundColor = .clear
                configuration?.background = background
                configuration?.baseBackgroundColor = .clear

                if button.isSelected {
                    configuration?.title = selectedText
                    configuration?.image = followingIcon
                    configuration?.baseForegroundColor = selectedColor
                } else if button.isHighlighted {
                    configuration?.title = selectedText
                    configuration?.image = followingIcon
                    configuration?.baseForegroundColor = highlightedColor
                } else {
                    configuration?.title = normalText
                    configuration?.image = followIcon
                    configuration?.baseForegroundColor = normalColor
                }
                button.configuration = configuration
            }

            // Default accessibility label and hint.
            button.accessibilityLabel = normalText
            button.accessibilityHint = NSLocalizedString("notifications.button.subscribedHint", value: "Subscribes to the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to subscribe to a blog.")
        }

        // MARK: - Constants
        //

        public static let followButtonImagePadding = CGFloat(4)

        // MARK: - Metrics
        //
        // Notification text is larger in a wide window. Every metric below takes the horizontal size class of
        // the window that displays the notification, not of the view: on a full-screen iPad, the split view
        // gives the notifications list column a compact size class.

        /// Appends the size class to a `FormattableContentStyles.key`, so text rendered for a wide window and
        /// text rendered for a narrow one are cached separately.
        public static func cacheKey(_ key: String, for sizeClass: UIUserInterfaceSizeClass) -> String {
            sizeClass == .regular ? "\(key)-regular" : "\(key)-compact"
        }

        public static func subjectNoticonSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            sizeClass == .regular ? CGFloat(15) : CGFloat(14)
        }

        public static func subjectLineSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            sizeClass == .regular ? CGFloat(24) : CGFloat(18)
        }

        public static func snippetLineSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            subjectLineSize(for: sizeClass)
        }

        public static func blockFontSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            sizeClass == .regular ? CGFloat(16) : CGFloat(14)
        }

        public static func blockLineSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            sizeClass == .regular ? CGFloat(24) : CGFloat(20)
        }

        public static func contentBlockLineSize(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            sizeClass == .regular ? CGFloat(24) : CGFloat(21)
        }

        // MARK: - Private Propreties
        //

        // ParagraphStyle's
        fileprivate static func subjectParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).subjectParagraph
        }
        fileprivate static func snippetParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).snippetParagraph
        }
        fileprivate static func snippetHeaderParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).snippetHeaderParagraph
        }
        fileprivate static func blockParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).blockParagraph
        }
        fileprivate static func contentBlockParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).contentBlockParagraph
        }
        fileprivate static func badgeParagraph(for sizeClass: UIUserInterfaceSizeClass) -> NSParagraphStyle {
            SizeClassResources.for(sizeClass).badgeParagraph
        }

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

        fileprivate static func subjectNoticonFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).subjectNoticonFont
        }

        fileprivate static func headerTitleRegularFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            blockRegularFont(for: sizeClass)
        }

        fileprivate static func headerTitleItalicsFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            blockItalicsFont(for: sizeClass)
        }

        fileprivate static func blockItalicsFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            SizeClassResources.for(sizeClass).blockItalicsFont
        }

        fileprivate static func blockNoticonFont(for sizeClass: UIUserInterfaceSizeClass) -> UIFont {
            subjectNoticonFont(for: sizeClass)
        }
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

/// The fonts and paragraph styles of `WPStyleGuide.Notifications` for one horizontal size class.
///
/// Built once per size class: notification rows and detail blocks ask for them on every render.
private struct SizeClassResources {
    let subjectParagraph: NSParagraphStyle
    let snippetParagraph: NSParagraphStyle
    let snippetHeaderParagraph: NSParagraphStyle
    let blockParagraph: NSParagraphStyle
    let contentBlockParagraph: NSParagraphStyle
    let badgeParagraph: NSParagraphStyle

    let subjectNoticonFont: UIFont
    let contentBlockRegularFont: UIFont
    let contentBlockBoldFont: UIFont
    let contentBlockItalicFont: UIFont
    let blockRegularFont: UIFont
    let blockBoldFont: UIFont
    let blockItalicsFont: UIFont

    private static let regular = SizeClassResources(sizeClass: .regular)
    private static let compact = SizeClassResources(sizeClass: .compact)

    /// The resources for a size class; anything but `.regular` gets the compact ones.
    static func `for`(_ sizeClass: UIUserInterfaceSizeClass) -> SizeClassResources {
        sizeClass == .regular ? regular : compact
    }

    private init(sizeClass: UIUserInterfaceSizeClass) {
        typealias Style = WPStyleGuide.Notifications
        func paragraph(
            lineHeight: CGFloat,
            lineBreakMode: NSLineBreakMode,
            alignment: NSTextAlignment
        ) -> NSParagraphStyle {
            NSMutableParagraphStyle(minLineHeight: lineHeight, lineBreakMode: lineBreakMode, alignment: alignment)
        }
        let subjectLineSize = Style.subjectLineSize(for: sizeClass)
        let snippetLineSize = Style.snippetLineSize(for: sizeClass)
        let blockLineSize = Style.blockLineSize(for: sizeClass)
        subjectParagraph = paragraph(lineHeight: subjectLineSize, lineBreakMode: .byWordWrapping, alignment: .natural)
        snippetParagraph = paragraph(lineHeight: snippetLineSize, lineBreakMode: .byWordWrapping, alignment: .natural)
        snippetHeaderParagraph = paragraph(
            lineHeight: snippetLineSize,
            lineBreakMode: .byTruncatingTail,
            alignment: .natural
        )
        blockParagraph = paragraph(lineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .natural)
        contentBlockParagraph = paragraph(
            lineHeight: Style.contentBlockLineSize(for: sizeClass),
            lineBreakMode: .byWordWrapping,
            alignment: .natural
        )
        badgeParagraph = paragraph(lineHeight: blockLineSize, lineBreakMode: .byWordWrapping, alignment: .center)

        let blockFontSize = Style.blockFontSize(for: sizeClass)
        subjectNoticonFont = UIFont(name: "Noticons", size: Style.subjectNoticonSize(for: sizeClass))!
        contentBlockRegularFont = WPFontManager.notoRegularFont(ofSize: blockFontSize)
        contentBlockBoldFont = WPFontManager.notoBoldFont(ofSize: blockFontSize)
        contentBlockItalicFont = WPFontManager.notoItalicFont(ofSize: blockFontSize)
        blockRegularFont = WPFontManager.systemRegularFont(ofSize: blockFontSize)
        blockBoldFont = WPFontManager.systemSemiBoldFont(ofSize: blockFontSize)
        blockItalicsFont = WPFontManager.systemItalicFont(ofSize: blockFontSize)
    }
}
