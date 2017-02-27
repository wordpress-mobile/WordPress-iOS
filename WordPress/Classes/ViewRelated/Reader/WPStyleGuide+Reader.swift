import Foundation
import WordPressShared
import Gridicons

/// A WPStyleGuide extension with styles and methods specific to the Reader feature.
///
extension WPStyleGuide {

    // MARK: - System Defaults

    public class func accessoryDefaultTintColor() -> UIColor {
        return UIColor(fromRGBAColorWithRed: 199.0, green: 199.0, blue: 204.0, alpha: 1.0)
    }


    public class func cellDefaultHighlightColor() -> UIColor {
        return UIColor(fromRGBAColorWithRed: 217.0, green: 217.0, blue: 217.0, alpha: 1.0)
    }


    // MARK: - Original Post/Site Attribution Styles.

    public class func originalAttributionParagraphAttributes() -> [String: AnyObject] {
        let fontSize = originalAttributionFontSize()
        let font = WPFontManager.systemRegularFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.defaultLineSpacing
        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
        ]
    }

    public class func originalAttributionFontSize() -> CGFloat {
        return Cards.contentFontSize
    }


    // MARK: - Reader Card Styles

    public class func readerCardBlogNameLabelTextColor() -> UIColor {
        return mediumBlue()
    }

    public class func readerCardBlogNameLabelDisabledTextColor() -> UIColor {
        return darkGrey()
    }

    // MARK: - Custom Colors
    public class func readerCardCellBorderColor() -> UIColor {
        return UIColor(red: 215.0/255.0, green: 227.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    }

    public class func readerCardCellHighlightedBorderColor() -> UIColor {
        // #87a6bc
        return UIColor(red: 135/255.0, green: 166/255.0, blue: 188/255.0, alpha: 1.0)
    }

    // MARK: - Card Attributed Text Attributes

    public class func readerCrossPostTitleAttributes() -> [String: AnyObject] {
        let fontSize = Cards.crossPostTitleFontSize
        let font = WPFontManager.notoBoldFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: darkGrey()
        ]
    }

    public class func readerCrossPostBoldSubtitleAttributes() -> [String: AnyObject] {
        let fontSize = Cards.crossPostSubtitleFontSize
        let font = WPFontManager.systemBoldFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: grey()
        ]
    }

    public class func readerCrossPostSubtitleAttributes() -> [String: AnyObject] {
        let fontSize = Cards.crossPostSubtitleFontSize
        let font = WPFontManager.systemRegularFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.crossPostLineSpacing

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: grey()
        ]
    }

    public class func readerCardTitleAttributes() -> [String: AnyObject] {
        let fontSize = Cards.titleFontSize
        let font = WPFontManager.notoBoldFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.titleLineSpacing

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardSummaryAttributes() -> [String: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.notoRegularFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.contentLineSpacing
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardReadingTimeAttributes() -> [String: AnyObject] {
        let fontSize: CGFloat = Cards.subtextFontSize
        let font = WPFontManager.systemRegularFont(ofSize: fontSize)

        return [
            NSFontAttributeName: font,
        ]
    }

    // MARK: - Detail styles

    public class func readerDetailTitleAttributes() -> [String: AnyObject] {
        let fontSize = Detail.titleFontSize
        let font = WPFontManager.notoBoldFont(ofSize: fontSize)

        let lineHeight = Detail.titleLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }


    // MARK: - Stream Header Attributed Text Attributes

    public class func readerStreamHeaderDescriptionAttributes() -> [String: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.notoRegularFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.defaultLineSpacing
        paragraphStyle.alignment = .center

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }


    // MARK: - Apply Card Styles

    public class func applyReaderCardSiteButtonStyle(_ button: UIButton) {
        let fontSize = Cards.buttonFontSize
        button.titleLabel!.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        button.setTitleColor(mediumBlue(), for: UIControlState())
        button.setTitleColor(lightBlue(), for: .highlighted)
        button.setTitleColor(darkGrey(), for: .disabled)
    }

    public class func applyReaderCardBlogNameStyle(_ label: UILabel) {
        let fontSize = Cards.buttonFontSize
        label.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        label.textColor = readerCardBlogNameLabelTextColor()
        label.highlightedTextColor = lightBlue()
    }

    public class func applyReaderCardBylineLabelStyle(_ label: UILabel) {
        let fontSize: CGFloat = Cards.subtextFontSize
        label.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        label.textColor = greyLighten10()
    }

    public class func applyReaderCardTitleLabelStyle(_ label: UILabel) {
        label.textColor = darkGrey()
    }

    public class func applyReaderCardSummaryLabelStyle(_ label: UILabel) {
        label.textColor = darkGrey()
    }

    public class func applyReaderCardTagButtonStyle(_ button: UIButton) {
        let fontSize = Cards.subtextFontSize
        button.setTitleColor(mediumBlue(), for: UIControlState())
        button.setTitleColor(lightBlue(), for: .highlighted)
        button.titleLabel?.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        button.titleLabel?.allowsDefaultTighteningForTruncation = false
        button.titleLabel?.lineBreakMode = .byTruncatingTail
    }

    public class func applyReaderCardActionButtonStyle(_ button: UIButton) {
        let fontSize = Cards.buttonFontSize
        button.setTitleColor(greyLighten10(), for: UIControlState())
        button.setTitleColor(lightBlue(), for: .highlighted)
        button.setTitleColor(jazzyOrange(), for: .selected)
        button.setTitleColor(greyLighten10(), for: .disabled)
        button.titleLabel?.font = WPFontManager.systemRegularFont(ofSize: fontSize)
    }


    // MARK: - Apply Stream Header Styles

    public class func applyReaderStreamHeaderTitleStyle(_ label: UILabel) {
        let fontSize: CGFloat = 14.0
        label.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        label.textColor = darkGrey()
    }

    public class func applyReaderStreamHeaderDetailStyle(_ label: UILabel) {
        let fontSize: CGFloat = Cards.subtextFontSize
        label.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        label.textColor = greyDarken10()
    }

    public class func applyReaderSiteStreamDescriptionStyle(_ label: UILabel) {
        let fontSize = Cards.contentFontSize
        label.font = WPFontManager.notoRegularFont(ofSize: fontSize)
        label.textColor = darkGrey()
    }

    public class func applyReaderSiteStreamCountStyle(_ label: UILabel) {
        let fontSize: CGFloat = 12.0
        label.font = WPFontManager.systemRegularFont(ofSize: fontSize)
        label.textColor = grey()
    }


    // MARK: - Button Styles and Text

    public class func applyReaderFollowButtonStyle(_ button: UIButton) {
        let side = button.titleLabel?.font.pointSize ?? Cards.buttonFontSize
        let size = CGSize(width: side, height: side)
        let followStr = followStringForDisplay(false)
        let followingStr = followStringForDisplay(true)

        let followIcon = Gridicon.iconOfType(.readerFollow, withSize: size)
        let followingIcon = Gridicon.iconOfType(.readerFollowing, withSize: size)
        let tintedFollowIcon = followIcon.imageWithTintColor(WPStyleGuide.mediumBlue())

        let tintedFollowingIcon = followingIcon.imageWithTintColor(WPStyleGuide.validGreen())
        let highlightIcon = followingIcon.imageWithTintColor(WPStyleGuide.lightBlue())

        button.setImage(tintedFollowIcon, for: .normal)
        button.setImage(tintedFollowingIcon, for: .selected)
        button.setImage(highlightIcon, for: .highlighted)

        button.setTitle(followStr, for: UIControlState())
        button.setTitle(followingStr, for: .selected)
        button.setTitle(followingStr, for: .highlighted)
    }

    public class func likeCountForDisplay(_ count: Int) -> String {
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

    public class func commentCountForDisplay(_ count: Int) -> String {
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

    public class func followStringForDisplay(_ isFollowing: Bool) -> String {
        if isFollowing {
            return NSLocalizedString("Following", comment: "Verb. Button title. The user is following a blog.")
        } else {
            return NSLocalizedString("Follow", comment: "Verb. Button title. Follow a new blog.")
        }
    }


    // MARK: - Gap Marker Styles

    public class func applyGapMarkerButtonStyle(_ button: UIButton) {
        button.backgroundColor = gapMarkerButtonBackgroundColor()
        button.titleLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: Cards.loadMoreButtonFontSize)
        button.setTitleColor(UIColor.white, for: UIControlState())
    }

    public class func gapMarkerButtonBackgroundColor() -> UIColor {
        return WPStyleGuide.greyDarken10()
    }

    public class func gapMarkerButtonBackgroundColorHighlighted() -> UIColor {
        return WPStyleGuide.lightBlue()
    }


    // MARK: - Metrics

    public struct Cards {
        public static let defaultLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 6.0 : 3.0
        public static let titleFontSize: CGFloat = WPDeviceIdentification.isiPad() ? 24.0 : 18.0
        public static let titleLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 0.0 : 0.0
        public static let contentFontSize: CGFloat = 15.0
        public static let contentLineSpacing: CGFloat = 4
        public static let buttonFontSize: CGFloat = 14.0
        public static let subtextFontSize: CGFloat = 12.0
        public static let loadMoreButtonFontSize: CGFloat = 15.0
        public static let crossPostTitleFontSize: CGFloat = 16.0
        public static let crossPostSubtitleFontSize: CGFloat = 13.0
        public static let crossPostLineSpacing: CGFloat = 2.0
    }

    public struct Detail {
        public static let titleFontSize: CGFloat = WPDeviceIdentification.isiPad() ? 36.0 : 26.0
        public static let titleLineHeight: CGFloat = WPDeviceIdentification.isiPad() ? 46.0 : 34.0
        public static let contentFontSize: CGFloat = 16.0
        public static let contentLineHeight: CGFloat = 27.0
    }

}
