import Foundation
import WordPressShared
import Gridicons
import AMScrollingNavbar

/// A WPStyleGuide extension with styles and methods specific to the Reader feature.
///
extension WPStyleGuide {

    // MARK: - Original Post/Site Attribution Styles.

    @objc public class func originalAttributionParagraphAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(originalAttributionTextStyle())

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.defaultLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
        ]
    }

    @objc public class func originalAttributionTextStyle() -> UIFont.TextStyle {
        return Cards.contentTextStyle
    }


    // MARK: - Reader Card Styles

    @objc public class func readerCardBlogNameLabelTextColor() -> UIColor {
        return UIColor(light: .muriel(color: .gray, .shade90),
                       dark: .muriel(color: .gray, .shade0))
    }

    @objc public class func readerCardBlogNameLabelDisabledTextColor() -> UIColor {
        return .neutral(.shade70)
    }

    // MARK: - Custom Colors
    @objc public class func readerCardCellBorderColor() -> UIColor {
        return .divider
    }

    @objc public class func readerCardCellHighlightedBorderColor() -> UIColor {
        return .neutral(.shade10)
    }

    public class func readerCardBlogIconBorderColor() -> UIColor {
        return UIColor(light: .gray(.shade0), dark: .systemGray5)
    }

    public class func readerCardFeaturedMediaBorderColor() -> UIColor {
        return readerCardBlogIconBorderColor()
    }

    // MARK: - Card Attributed Text Attributes

    @objc public class func readerCrossPostTitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.serifFontForTextStyle(Cards.crossPostTitleTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor.text
        ]
    }

    @objc public class func readerCrossPostBoldSubtitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(Cards.crossPostSubtitleTextStyle, symbolicTraits: .traitBold)

        let paragraphStyle = NSMutableParagraphStyle()
        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor(light: .gray(.shade40), dark: .systemGray)
        ]
    }

    @objc public class func readerCrossPostSubtitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(Cards.crossPostSubtitleTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor(light: .gray(.shade40), dark: .systemGray)
        ]
    }

    @objc public class func readerCardTitleAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.titleLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: WPStyleGuide.serifFontForTextStyle(Cards.titleTextStyle, fontWeight: .semibold)
        ]
    }

    @objc public class func readerCardSummaryAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(Cards.summaryTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.contentLineSpacing
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            .paragraphStyle: paragraphStyle,
            .font: font
        ]
    }

    @objc public class func readerCardReadingTimeAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(Cards.subtextTextStyle)

        return [.font: font]
    }

    // MARK: - Detail styles

    @objc public class func readerDetailTitleAttributes() -> [NSAttributedString.Key: Any] {
        let style: UIFont.TextStyle = UIDevice.isPad() ? .title1 : .title2
        let font = WPStyleGuide.serifFontForTextStyle(style, fontWeight: .semibold)

        return [
            .font: font
        ]
    }

    // MARK: - No Followed Sites Error Text Attributes
    @objc public class func noFollowedSitesErrorTitleAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()

        return [
            .paragraphStyle: paragraphStyle,
            .font: WPStyleGuide.serifFontForTextStyle(.title3),

        ]
    }

    @objc public class func noFollowedSitesErrorSubtitleAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        return [
            .paragraphStyle: paragraphStyle,
            .font: fontForTextStyle(.subheadline),
            .foregroundColor: UIColor(light: .muriel(color: .gray, .shade40),
                                      dark: .muriel(color: .gray, .shade20))
        ]
    }

    // MARK: - Apply Card Styles

    @objc public class func applyReaderCardSiteButtonStyle(_ button: UIButton) {
        guard let titleLabel = button.titleLabel else {
            return
        }
        WPStyleGuide.configureLabel(titleLabel, textStyle: Cards.buttonTextStyle)
        button.setTitleColor(.primary, for: UIControl.State())
        button.setTitleColor(.primaryDark, for: .highlighted)
        button.setTitleColor(.text, for: .disabled)
    }

    @objc public class func applyReaderCardBlogNameStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.buttonTextStyle, fontWeight: .medium)
        label.textColor = readerCardBlogNameLabelTextColor()
        label.highlightedTextColor = .primaryLight
    }

    @objc public class func applyReaderCardBylineLabelStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.subtextTextStyle)
        label.textColor = UIColor(light: .muriel(color: .gray, .shade40),
                                  dark: .muriel(color: .gray, .shade20))
    }

    @objc public class func applyReaderCardTitleLabelStyle(_ label: UILabel) {
        label.textColor = UIColor(light: .gray(.shade90), dark: .text)
    }

    @objc public class func applyReaderCardSummaryLabelStyle(_ label: UILabel) {
        label.textColor = UIColor(light: .gray(.shade80), dark: .muriel(color: .gray, .shade0))
    }

    public class func applyReaderCardAttributionLabelStyle(_ label: UILabel) {
        label.textColor = UIColor(light: .gray(.shade80), dark: .textSubtle)
    }

    @objc public class func applyReaderCardActionButtonStyle(_ button: UIButton) {
        guard let titleLabel = button.titleLabel else {
            return
        }
        WPStyleGuide.configureLabel(titleLabel, textStyle: Cards.buttonTextStyle)

        WPStyleGuide.applyReaderActionButtonStyle(button)
    }

    // MARK: - Apply Stream Header Styles

    @objc public class func applyReaderStreamHeaderTitleStyle(_ label: UILabel) {
        label.font = WPStyleGuide.serifFontForTextStyle(.title2, fontWeight: .bold)
        label.textColor = .text
    }

    @objc public class func applyReaderStreamHeaderDetailStyle(_ label: UILabel) {
        label.font = fontForTextStyle(.subheadline, fontWeight: .regular)
        label.textColor = .textSubtle
    }

    @objc public class func applyReaderSiteStreamDescriptionStyle(_ label: UILabel) {
        label.font = fontForTextStyle(.body, fontWeight: .regular)
        label.textColor = .text
    }

    @objc public class func applyReaderSiteStreamCountStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.contentTextStyle)
        label.textColor = .textSubtle
    }


    // MARK: - Button Styles and Text
    class func applyReaderStreamActionButtonStyle(_ button: UIButton) {
        let tintColor = UIColor(light: .muriel(color: .gray, .shade50),
                                dark: .textSubtle)

        let disabledColor = UIColor(light: .muriel(color: .gray, .shade10),
                                    dark: .textQuaternary)

        return applyReaderActionButtonStyle(button,
                                            titleColor: tintColor,
                                            imageColor: tintColor,
                                            disabledColor: disabledColor)
    }


    class func applyReaderActionButtonStyle(_ button: UIButton,
                                            titleColor: UIColor = .listIcon,
                                            imageColor: UIColor = .listIcon,
                                            disabledColor: UIColor = .neutral(.shade10)) {
        button.tintColor = imageColor
        let highlightedColor: UIColor = .neutral
        let selectedColor: UIColor = .primary(.shade40)
        let bothColor: UIColor = .primaryLight

        let highlightedImage = button.image(for: .highlighted)
        let selectedImage = button.image(for: .selected)
        let bothImage = button.image(for: [.highlighted, .selected])
        let disabledImage = button.image(for: .disabled)

        button.setImage(highlightedImage?.imageWithTintColor(highlightedColor), for: .highlighted)
        button.setImage(selectedImage?.imageWithTintColor(selectedColor), for: .selected)
        button.setImage(bothImage?.imageWithTintColor(bothColor), for: [.selected, .highlighted])
        button.setImage(disabledImage?.imageWithTintColor(disabledColor), for: .disabled)

        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(highlightedColor, for: .highlighted)
        button.setTitleColor(selectedColor, for: .selected)
        button.setTitleColor(bothColor, for: [.selected, .highlighted])
        button.setTitleColor(disabledColor, for: .disabled)
    }

    @objc public class func applyReaderFollowConversationButtonStyle(_ button: UIButton) {
        // General
        button.naturalContentHorizontalAlignment = .leading
        button.backgroundColor = .clear
        button.titleLabel?.font = fontForTextStyle(.footnote)

        // Color(s)
        let normalColor = UIColor.primary
        let highlightedColor =  UIColor.neutral
        let selectedColor = UIColor.success

        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(selectedColor, for: .selected)
        button.setTitleColor(highlightedColor, for: .highlighted)

        // Image(s)
        let side = WPStyleGuide.fontSizeForTextStyle(.headline)
        let size = CGSize(width: side, height: side)
        let followIcon = UIImage.gridicon(.readerFollowConversation, size: size)
        let followingIcon = UIImage.gridicon(.readerFollowingConversation, size: size)

        button.setImage(followIcon.imageWithTintColor(normalColor), for: .normal)
        button.setImage(followingIcon.imageWithTintColor(selectedColor), for: .selected)
        button.setImage(followingIcon.imageWithTintColor(highlightedColor), for: .highlighted)
        button.imageEdgeInsets = FollowConversationButton.Style.imageEdgeInsets
        button.contentEdgeInsets = FollowConversationButton.Style.contentEdgeInsets
    }

    @objc public class func applyReaderFollowButtonStyle(_ button: UIButton) {
        let side = WPStyleGuide.fontSizeForTextStyle(.callout)
        let size = CGSize(width: side, height: side)

        let followIcon = UIImage.gridicon(.readerFollow, size: size)
        let followingIcon = UIImage.gridicon(.readerFollowing, size: size)

        let followFont: UIFont = fontForTextStyle(.callout, fontWeight: .semibold)
        let followingFont: UIFont = fontForTextStyle(.callout, fontWeight: .regular)
        button.titleLabel?.font = button.isSelected ? followingFont : followFont

        button.layer.cornerRadius = 4.0
        button.layer.borderColor = UIColor.primaryButtonBorder.cgColor

        button.backgroundColor = button.isSelected ? FollowButton.Style.followingBackgroundColor : FollowButton.Style.followBackgroundColor
        button.tintColor = button.isSelected ? FollowButton.Style.followingIconColor : FollowButton.Style.followTextColor

        button.setTitleColor(FollowButton.Style.followTextColor, for: .normal)
        button.setTitleColor(FollowButton.Style.followingTextColor, for: .selected)

        button.imageEdgeInsets = FollowButton.Style.imageEdgeInsets
        button.titleEdgeInsets = FollowButton.Style.titleEdgeInsets
        button.contentEdgeInsets = FollowButton.Style.contentEdgeInsets

        let tintedFollowIcon = followIcon.imageWithTintColor(FollowButton.Style.followTextColor)
        let tintedFollowingIcon = followingIcon.imageWithTintColor(FollowButton.Style.followingTextColor)

        button.setImage(tintedFollowIcon, for: .normal)
        button.setImage(tintedFollowingIcon, for: .selected)

        button.setTitle(FollowButton.Text.followStringForDisplay, for: .normal)
        button.setTitle(FollowButton.Text.followingStringForDisplay, for: .selected)

        button.layer.borderWidth = button.isSelected ? 1.0 : 0.0

        // Default accessibility label and hint.
        button.accessibilityLabel = button.isSelected ? FollowButton.Text.followingStringForDisplay : FollowButton.Text.followStringForDisplay
        button.accessibilityHint = FollowButton.Text.accessibilityHint
    }

    @objc public class func applyReaderIconFollowButtonStyle(_ button: UIButton) {
        let followIcon = UIImage.gridicon(.readerFollow)
        let followingIcon = UIImage.gridicon(.readerFollowing)

        button.backgroundColor = .clear

        let tintedFollowIcon = followIcon.imageWithTintColor(.primary(.shade40))
        let tintedFollowingIcon = followingIcon.imageWithTintColor(.gray(.shade40))

        button.setImage(tintedFollowIcon, for: .normal)
        button.setImage(tintedFollowingIcon, for: .selected)

        // Default accessibility label and hint.
        button.accessibilityLabel = button.isSelected ? FollowButton.Text.followingStringForDisplay : FollowButton.Text.followStringForDisplay
        button.accessibilityHint = FollowButton.Text.accessibilityHint
    }

    @objc public class func applyReaderSaveForLaterButtonStyle(_ button: UIButton) {
        let size = Gridicon.defaultSize
        let icon = UIImage.gridicon(.bookmarkOutline, size: size)
        let selectedIcon = UIImage.gridicon(.bookmark, size: size)

        button.setImage(icon, for: .normal)
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: .highlighted)
        button.setImage(selectedIcon, for: [.highlighted, .selected])

        applyReaderActionButtonStyle(button)
    }

    @objc public class func applyReaderCardSaveForLaterButtonStyle(_ button: UIButton) {
        let size = Cards.actionButtonSize
        let icon = UIImage.gridicon(.bookmarkOutline, size: size)
        let selectedIcon = UIImage.gridicon(.bookmark, size: size)

        button.setImage(icon, for: .normal)
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: .highlighted)
        button.setImage(selectedIcon, for: [.highlighted, .selected])
        button.setImage(icon, for: .disabled)

        applyReaderStreamActionButtonStyle(button)
    }

    @objc public class func applyReaderCardCommentButtonStyle(_ button: UIButton, defaultSize: Bool = false) {
        let size = defaultSize ? Gridicon.defaultSize : Cards.actionButtonSize
        let icon = UIImage(named: "icon-reader-comment-outline")?.imageFlippedForRightToLeftLayoutDirection()
        let selectedIcon = UIImage(named: "icon-reader-comment-outline-highlighted")?.imageFlippedForRightToLeftLayoutDirection()

        guard
            let resizedIcon = icon?.resizedImage(size, interpolationQuality: .high)?.withRenderingMode(.alwaysTemplate),
            let resizedSelectedIcon = selectedIcon?.resizedImage(size, interpolationQuality: .high).withRenderingMode(.alwaysTemplate)
        else {
            return
        }

        button.setImage(resizedIcon, for: .normal)
        button.setImage(resizedSelectedIcon, for: .selected)
        button.setImage(resizedSelectedIcon, for: .highlighted)
        button.setImage(resizedSelectedIcon, for: [.highlighted, .selected])
        button.setImage(resizedIcon, for: .disabled)

        applyReaderStreamActionButtonStyle(button)
    }

    @objc public class func applyReaderCardLikeButtonStyle(_ button: UIButton) {
        let size = Cards.actionButtonSize
        let icon = UIImage.gridicon(.starOutline, size: size)
        let selectedIcon = UIImage.gridicon(.star, size: size)

        button.setImage(icon, for: .normal)
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: .highlighted)
        button.setImage(selectedIcon, for: [.highlighted, .selected])
        button.setImage(icon, for: .disabled)

        applyReaderStreamActionButtonStyle(button)
    }

    /// Applies the save for later button style to the button passed as an argument
    /// - Parameter button: the button to apply the style to
    /// - Parameter showTitle: if set to true, will show the button label (default: true)
    @objc public class func applyReaderSaveForLaterButtonTitles(_ button: UIButton, showTitle: Bool = true) {
        let saveTitle = showTitle ? WPStyleGuide.savePostStringForDisplay(false) : ""
        let savedTitle = showTitle ? WPStyleGuide.savePostStringForDisplay(true) : ""

        button.setTitle(saveTitle, for: .normal)
        button.setTitle(savedTitle, for: .selected)
        button.setTitle(savedTitle, for: [.highlighted, .selected])
    }

    /// Applies the reblog button style to the button passed as an argument
    /// - Parameter button: the button to apply the style to
    /// - Parameter showTitle: if set to true, will show the button label (default: true)
    @objc public class func applyReaderCardReblogActionButtonStyle(_ button: UIButton, showTitle: Bool = true) {
        let size = Cards.actionButtonSize
        let icon = UIImage.gridicon(.reblog, size: size)

        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .selected)
        button.setImage(icon, for: .highlighted)
        button.setImage(icon, for: [.highlighted, .selected])
        button.setImage(icon, for: .disabled)

        applyReaderStreamActionButtonStyle(button)
    }
    /// Applies the reblog button style to the button passed as an argument
    /// - Parameter button: the button to apply the style to
    /// - Parameter showTitle: if set to true, will show the button label (default: true)
    @objc public class func applyReaderReblogActionButtonStyle(_ button: UIButton, showTitle: Bool = true) {
        let size = Gridicon.defaultSize
        let icon = UIImage.gridicon(.reblog, size: size)

        button.setImage(icon, for: .normal)

        WPStyleGuide.applyReaderReblogActionButtonTitle(button, showTitle: showTitle)
        WPStyleGuide.applyReaderActionButtonStyle(button)
    }

    /// Applies the reblog button title to the button passed as an argument
    /// - Parameter button: the button to apply the title to
    /// - Parameter showTitle: if  true, will show the button label (default: true), if false, the label will be empty (button with no label)
    @objc public class func applyReaderReblogActionButtonTitle(_ button: UIButton, showTitle: Bool = true) {
        let title = showTitle ? NSLocalizedString("Reblog", comment: "Text for the 'Reblog' button.") : ""
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
    }

    @objc public class func likeCountForDisplay(_ count: Int) -> String {
        let likeStr = NSLocalizedString("Like", comment: "Text for the 'like' button. Tapping marks a post in the reader as 'liked'.")
        let likesStr = NSLocalizedString("Likes", comment: "Text for the 'like' button. Tapping removes the 'liked' status from a post.")

        if count == 0 {
            return likeStr
        } else if count == 1 {
            return "\(count) \(likeStr)"
        } else {
            return "\(count) \(likesStr)"
        }
    }

    @objc public class func commentCountForDisplay(_ count: Int) -> String {
        let commentStr = NSLocalizedString("Comment", comment: "Text for the 'comment' when there is 1 or 0 comments")
        let commentsStr = NSLocalizedString("Comments", comment: "Text for the 'comment' button when there are multiple comments")

        if count == 0 {
            return commentStr
        } else if count == 1 {
            return "\(count) \(commentStr)"
        } else {
            return "\(count) \(commentsStr)"
        }
    }

    @objc public class func savePostStringForDisplay(_ isSaved: Bool) -> String {
        if isSaved {
            return NSLocalizedString("Saved", comment: "Title of action button for a Reader post that has been saved to read later.")
        } else {
            return NSLocalizedString("Save", comment: "Title of action button to save a Reader post to read later.")
        }
    }

    /// Applies the filter button style to the button passed as an argument
    class func applyReaderFilterButtonStyle(_ button: UIButton) {
        let icon = UIImage.gridicon(.filter)

        button.setImage(icon, for: .normal)
        applyReaderActionButtonStyle(button, titleColor: UIColor(light: .black, dark: .white))
    }
    /// Applies the filter button title to the button passed as an argument
    class func applyReaderFilterButtonTitle(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
    }
    /// Applies the reset filter button style to the button passed as an argument
    class func applyReaderResetFilterButtonStyle(_ button: UIButton) {
        let icon = UIImage.gridicon(.crossSmall)

        button.setImage(icon, for: .normal)
        applyReaderActionButtonStyle(button, imageColor: UIColor(light: .black, dark: .white))
    }
    /// Applies the settings button style to the button passed as an argument
    class func applyReaderSettingsButtonStyle(_ button: UIButton) {
        let icon = UIImage.gridicon(.cog)

        button.setImage(icon, for: .normal)
        applyReaderActionButtonStyle(button)
    }

    // MARK: - Gap Marker Styles

    @objc public class func applyGapMarkerButtonStyle(_ button: UIButton) {
        button.backgroundColor = gapMarkerButtonBackgroundColor()
        guard let titleLabel = button.titleLabel else {
            return
        }
        WPStyleGuide.configureLabel(titleLabel, textStyle: Cards.loadMoreButtonTextStyle, fontWeight: .semibold)
        button.setTitleColor(UIColor.white, for: UIControl.State())
    }

    @objc public class func gapMarkerButtonBackgroundColor() -> UIColor {
        return .neutral(.shade40)
    }

    @objc public class func gapMarkerButtonBackgroundColorHighlighted() -> UIColor {
        return .primaryLight
    }


    // MARK: - Metrics

    public struct Cards {
        public static let defaultLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 6.0 : 3.0
        public static let titleTextStyle: UIFont.TextStyle = WPDeviceIdentification.isiPad() ? .title2 : .title3
        public static let titleLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 0.0 : 0.0
        public static let summaryTextStyle: UIFont.TextStyle = .subheadline
        public static let contentTextStyle: UIFont.TextStyle = .footnote
        public static let contentLineSpacing: CGFloat = 4
        public static let buttonTextStyle: UIFont.TextStyle = .subheadline
        public static let subtextTextStyle: UIFont.TextStyle = .caption1
        public static let loadMoreButtonTextStyle: UIFont.TextStyle = .subheadline

        public static let crossPostTitleTextStyle: UIFont.TextStyle = .body
        public static let crossPostSubtitleTextStyle: UIFont.TextStyle = .caption1
        public static let crossPostLineSpacing: CGFloat = 2.0

        public static let actionButtonSize: CGSize = CGSize(width: 20, height: 20)
    }

    public struct Detail {
        public static let titleTextStyle: UIFont.TextStyle = .title2
        public static let contentTextStyle: UIFont.TextStyle = .callout
    }

    public struct FollowButton {
        struct Style {
            static let followBackgroundColor: UIColor = .primaryButtonBackground
            static let followTextColor: UIColor = .white
            static let followingBackgroundColor: UIColor = .clear
            static let followingIconColor: UIColor = .buttonIcon
            static let followingTextColor: UIColor = .textSubtle

            static let imageTitleSpace: CGFloat = 2.0
            static let imageEdgeInsets = UIEdgeInsets(top: 0, left: -imageTitleSpace, bottom: 0, right: imageTitleSpace)
            static let titleEdgeInsets = UIEdgeInsets(top: 0, left: imageTitleSpace, bottom: 0, right: -imageTitleSpace)
            static let contentEdgeInsets = UIEdgeInsets(top: 6.0, left: 12.0, bottom: 6.0, right: 12.0)
        }

        struct Text {
            static let accessibilityHint = NSLocalizedString("Follows the tag.", comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a tag.")
            static let followStringForDisplay =  NSLocalizedString("Follow", comment: "Verb. Button title. Follow a new blog.")
            static let followingStringForDisplay = NSLocalizedString("Following", comment: "Verb. Button title. The user is following a blog.")
        }
    }

    public struct FollowConversationButton {
        struct Style {
            static let imageEdgeInsets = UIEdgeInsets(top: 1.0, left: -4.0, bottom: 0.0, right: -4.0)
            static let contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 0.0)
        }
    }
}

extension ScrollingNavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return WPStyleGuide.preferredStatusBarStyle
    }
}
