import Foundation
import WordPressShared
import Gridicons

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
        if #available(iOS 13.0, *) {
            return UIColor(light: .gray(.shade0), dark: .systemGray5)
        } else {
            return .neutral(.shade0)
        }
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
        let font = WPStyleGuide.notoBoldFontForTextStyle(Detail.titleTextStyle)

        let lineHeight = font.pointSize + 10.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            .paragraphStyle: paragraphStyle,
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

    // MARK: - Stream Header Attributed Text Attributes

    @objc public class func readerStreamHeaderDescriptionAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.notoFontForTextStyle(Cards.contentTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.defaultLineSpacing
        paragraphStyle.alignment = .center

        return [
            .paragraphStyle: paragraphStyle,
            .font: font
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

    @objc public class func applyReaderCardTagButtonStyle(_ button: UIButton) {
        WPStyleGuide.configureLabel(button.titleLabel!, textStyle: Cards.subtextTextStyle)
        button.setTitleColor(.primary, for: UIControl.State())
        button.setTitleColor(.primaryDark, for: .highlighted)
        button.titleLabel?.allowsDefaultTighteningForTruncation = false
        button.titleLabel?.lineBreakMode = .byTruncatingTail
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
        WPStyleGuide.configureLabel(label, textStyle: Cards.buttonTextStyle)
        label.textColor = .text
    }

    @objc public class func applyReaderStreamHeaderDetailStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.subtextTextStyle)
        label.textColor = .textSubtle
    }

    @objc public class func applyReaderSiteStreamDescriptionStyle(_ label: UILabel) {
        WPStyleGuide.configureLabelForNotoFont(label, textStyle: .subheadline)
        label.textColor = .text
    }

    @objc public class func applyReaderSiteStreamCountStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.subtextTextStyle)
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

    @objc public class func applyReaderFollowButtonStyle(_ button: UIButton) {
        let side = WPStyleGuide.fontSizeForTextStyle(Cards.buttonTextStyle)
        let size = CGSize(width: side, height: side)

        let followIcon = UIImage.gridicon(.readerFollow, size: size)
        let followingIcon = UIImage.gridicon(.readerFollowing, size: size)

        let normalColor = UIColor.primary
        let highlightedColor = UIColor.primaryDark
        let selectedColor = UIColor.success

        let tintedFollowIcon = followIcon.imageWithTintColor(normalColor)
        let tintedFollowingIcon = followingIcon.imageWithTintColor(selectedColor)
        let highlightIcon = followingIcon.imageWithTintColor(highlightedColor)

        button.setImage(tintedFollowIcon, for: .normal)
        button.setImage(tintedFollowingIcon, for: .selected)
        button.setImage(highlightIcon, for: .highlighted)

        button.setTitle(followStringForDisplay, for: UIControl.State())
        button.setTitle(followingStringForDisplay, for: .selected)
        button.setTitle(followingStringForDisplay, for: .highlighted)

        button.setTitleColor(normalColor, for: UIControl.State())
        button.setTitleColor(highlightedColor, for: .highlighted)
        button.setTitleColor(selectedColor, for: .selected)
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

    @objc public class func applyReaderCardCommentButtonStyle(_ button: UIButton) {
        let size = Cards.actionButtonSize
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

    @objc public static var followStringForDisplay: String {
        return NSLocalizedString("Follow", comment: "Verb. Button title. Follow a new blog.")
    }

    @objc public static var followingStringForDisplay: String {
        return NSLocalizedString("Following", comment: "Verb. Button title. The user is following a blog.")
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
        public static let titleTextStyle: UIFont.TextStyle = .title1
        public static let contentTextStyle: UIFont.TextStyle = .callout
    }

}
