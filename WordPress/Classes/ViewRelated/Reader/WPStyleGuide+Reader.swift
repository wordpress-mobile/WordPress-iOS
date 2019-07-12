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
        return .primary
    }

    @objc public class func readerCardBlogNameLabelDisabledTextColor() -> UIColor {
        return .neutral(shade: .shade70)
    }

    // MARK: - Custom Colors
    @objc public class func readerCardCellBorderColor() -> UIColor {
        return .neutral(shade: .shade10)
    }

    @objc public class func readerCardCellHighlightedBorderColor() -> UIColor {
        return .neutral
    }

    // MARK: - Card Attributed Text Attributes

    @objc public class func readerCrossPostTitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.notoBoldFontForTextStyle(Cards.titleTextStyle)

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
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor.textSubtle
        ]
    }

    @objc public class func readerCrossPostSubtitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(Cards.crossPostSubtitleTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor.textSubtle
        ]
    }

    @objc public class func readerCardTitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.notoBoldFontForTextStyle(Cards.titleTextStyle)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.titleLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font
        ]
    }

    @objc public class func readerCardSummaryAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.notoFontForTextStyle(Cards.contentTextStyle)

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
        WPStyleGuide.configureLabel(label, textStyle: Cards.buttonTextStyle)
        label.textColor = readerCardBlogNameLabelTextColor()
        label.highlightedTextColor = .primaryLight
    }

    @objc public class func applyReaderCardBylineLabelStyle(_ label: UILabel) {
        WPStyleGuide.configureLabel(label, textStyle: Cards.subtextTextStyle)
        label.textColor = UIColor.textSubtle
    }

    @objc public class func applyReaderCardTitleLabelStyle(_ label: UILabel) {
        label.textColor = .text
    }

    @objc public class func applyReaderCardSummaryLabelStyle(_ label: UILabel) {
        label.textColor = .text
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
        button.setTitleColor(.neutral(shade: .shade30), for: UIControl.State())
        button.setTitleColor(.neutral, for: .highlighted)
        button.setTitleColor(.primary(shade: .shade40), for: .selected)
        button.setTitleColor(.neutral(shade: .shade10), for: .disabled)
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

    @objc public class func applyReaderFollowButtonStyle(_ button: UIButton) {
        let side = WPStyleGuide.fontSizeForTextStyle(Cards.buttonTextStyle)
        let size = CGSize(width: side, height: side)

        let followIcon = Gridicon.iconOfType(.readerFollow, withSize: size)
        let followingIcon = Gridicon.iconOfType(.readerFollowing, withSize: size)

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
        let icon = Gridicon.iconOfType(.bookmarkOutline, withSize: size)
        let selectedIcon = Gridicon.iconOfType(.bookmark, withSize: size)

        let normalColor: UIColor = .neutral(shade: .shade30)
        let selectedColor: UIColor = .primary(shade: .shade40)
        let highlightedColor: UIColor = .neutral

        let tintedIcon = icon.imageWithTintColor(normalColor)
        let tintedSelectedIcon = selectedIcon.imageWithTintColor(selectedColor)
        let tintedHighlightedIcon = icon.imageWithTintColor(highlightedColor)
        let tintedSelectedHighlightedIcon = selectedIcon.imageWithTintColor(highlightedColor)

        button.setImage(tintedIcon, for: .normal)
        button.setImage(tintedSelectedIcon, for: .selected)
        button.setImage(tintedHighlightedIcon, for: .highlighted)
        button.setImage(tintedSelectedHighlightedIcon, for: [.highlighted, .selected])

        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(selectedColor, for: .selected)
        button.setTitleColor(highlightedColor, for: .highlighted)
        button.setTitleColor(highlightedColor, for: [.highlighted, .selected])
    }

    @objc public class func applyReaderSaveForLaterButtonTitles(_ button: UIButton) {
        let saveTitle = WPStyleGuide.savePostStringForDisplay(false)
        let savedTitle = WPStyleGuide.savePostStringForDisplay(true)

        button.setTitle(saveTitle, for: .normal)
        button.setTitle(savedTitle, for: .selected)
        button.setTitle(savedTitle, for: [.highlighted, .selected])
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
        return .neutral(shade: .shade40)
    }

    @objc public class func gapMarkerButtonBackgroundColorHighlighted() -> UIColor {
        return .primaryLight
    }


    // MARK: - Metrics

    public struct Cards {
        public static let defaultLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 6.0 : 3.0
        public static let titleTextStyle: UIFont.TextStyle = WPDeviceIdentification.isiPad() ? .title2 : .title3
        public static let titleLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 0.0 : 0.0
        public static let contentTextStyle: UIFont.TextStyle = .subheadline
        public static let contentLineSpacing: CGFloat = 4
        public static let buttonTextStyle: UIFont.TextStyle = .subheadline
        public static let subtextTextStyle: UIFont.TextStyle = .caption1
        public static let loadMoreButtonTextStyle: UIFont.TextStyle = .subheadline
        public static let crossPostSubtitleTextStyle: UIFont.TextStyle = .footnote
        public static let crossPostLineSpacing: CGFloat = 2.0
    }

    public struct Detail {
        public static let titleTextStyle: UIFont.TextStyle = .title1
        public static let contentTextStyle: UIFont.TextStyle = .callout
    }

}
