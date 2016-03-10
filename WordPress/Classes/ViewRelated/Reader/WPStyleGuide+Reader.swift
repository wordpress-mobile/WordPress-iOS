import Foundation
import WordPressShared

/**
    A WPStyleGuide extension with styles and methods specific to the
    Reader feature.
*/
extension WPStyleGuide
{

    // MARK: Original Post/Site Attribution Styles. 

    public class func originalAttributionParagraphAttributes() -> [String: AnyObject] {
        let fontSize = originalAttributionFontSize()
        let font = WPFontManager.systemRegularFontOfSize(fontSize)

        let lineHeight:CGFloat = Cards.defaultLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return [
            NSParagraphStyleAttributeName : paragraphStyle,
            NSFontAttributeName : font,
            NSForegroundColorAttributeName: grey(),
        ]
    }

    public class func siteAttributionParagraphAttributes() -> [String: AnyObject] {
        let attributes = NSMutableDictionary(dictionary: originalAttributionParagraphAttributes())
        attributes.setValue(mediumBlue(), forKey: NSForegroundColorAttributeName)
        return NSDictionary(dictionary: attributes) as! [String: AnyObject]
    }

    public class func originalAttributionFontSize() -> CGFloat {
        return Cards.contentFontSize
    }


    // MARK: - Reader Card Styles

    // MARK: - Custom Colors
    public class func readerCardCellBorderColor() -> UIColor {
        return UIColor(red: 215.0/255.0, green: 227.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    }

    public class func readerCardCellHighlightedBorderColor() -> UIColor {
        // #87a6bc
        return UIColor(red: 135/255.0, green: 166/255.0, blue: 188/255.0, alpha: 1.0)
    }

    // MARK: - Card Attributed Text Attributes

    public class func readerCrossPostTitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.crossPostTitleFontSize
        let font = WPFontManager.merriweatherBoldFontOfSize(fontSize)

        let lineHeight = Cards.crossPostLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: darkGrey()
        ]
    }

    public class func readerCrossPostBoldSubtitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.crossPostSubtitleFontSize
        let font = WPFontManager.systemBoldFontOfSize(fontSize)

        let lineHeight = Cards.crossPostLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: grey()
        ]
    }

    public class func readerCrossPostSubtitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.crossPostSubtitleFontSize
        let font = WPFontManager.systemRegularFontOfSize(fontSize)

        let lineHeight = Cards.crossPostLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: grey()
        ]
    }

    public class func readerCardTitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.titleFontSize
        let font = WPFontManager.merriweatherBoldFontOfSize(fontSize)

        let lineHeight = Cards.titleLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardSummaryAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.merriweatherRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardWordCountAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.buttonFontSize
        let font = WPFontManager.systemRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: greyDarken10()
        ]
    }

    public class func readerCardReadingTimeAttributes() -> [NSObject: AnyObject] {
        let fontSize:CGFloat = Cards.subtextFontSize
        let font = WPFontManager.systemRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: greyDarken10()
        ]
    }

    // MARK: - Detail styles

    public class func readerDetailTitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Detail.titleFontSize
        let font = WPFontManager.merriweatherBoldFontOfSize(fontSize)

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

    public class func readerStreamHeaderDescriptionAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.merriweatherRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = .Center

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }


    // MARK: - Apply Card Styles

    public class func applyReaderCardSiteButtonStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.titleLabel!.font = WPFontManager.systemRegularFontOfSize(fontSize)
        button.setTitleColor(mediumBlue(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.setTitleColor(darkGrey(), forState: .Disabled)
    }

    public class func applyReaderCardBylineLabelStyle(label:UILabel) {
        let fontSize:CGFloat = Cards.subtextFontSize
        label.font = WPFontManager.systemRegularFontOfSize(fontSize)
        label.textColor = greyDarken10()
    }

    public class func applyReaderCardTitleLabelStyle(label:UILabel) {
        label.textColor = darkGrey()
    }

    public class func applyReaderCardSummaryLabelStyle(label:UILabel) {
        label.textColor = darkGrey()
    }

    public class func applyReaderCardTagButtonStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.setTitleColor(mediumBlue(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.titleLabel?.font = WPFontManager.systemRegularFontOfSize(fontSize)
    }

    public class func applyReaderCardActionButtonStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.setTitleColor(greyDarken10(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.setTitleColor(jazzyOrange(), forState: .Selected)
        button.setTitleColor(greyDarken10(), forState: .Disabled)
        button.titleLabel?.font = WPFontManager.systemRegularFontOfSize(fontSize)
    }


    // MARK: - Apply Stream Header Styles

    public class func applyReaderStreamHeaderTitleStyle(label:UILabel) {
        let fontSize:CGFloat = 14.0
        label.font = WPFontManager.systemRegularFontOfSize(fontSize)
        label.textColor = darkGrey()
    }

    public class func applyReaderStreamHeaderDetailStyle(label:UILabel) {
        let fontSize:CGFloat = Cards.subtextFontSize
        label.font = WPFontManager.systemRegularFontOfSize(fontSize)
        label.textColor = greyDarken10()
    }

    public class func applyReaderStreamHeaderFollowingStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        let title = NSLocalizedString("Following", comment: "Gerund. A button label indicating the user is currently subscribed to a topic or site in ther eader. Tapping unsubscribes the user.")

        button.setTitle(title, forState: .Normal)
        button.setTitle(title, forState: .Highlighted)

        button.setTitleColor(validGreen(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.titleLabel?.font = WPFontManager.systemRegularFontOfSize(fontSize)

        button.setImage(UIImage(named: "icon-reader-following"), forState: .Normal)
        button.setImage(UIImage(named: "icon-reader-follow-highlight"), forState: .Highlighted)
    }

    public class func applyReaderStreamHeaderNotFollowingStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        let title = NSLocalizedString("Follow", comment: "Verb. A button label. Tapping subscribes the user to a topic or site in the reader")

        button.setTitle(title, forState: .Normal)
        button.setTitle(title, forState: .Highlighted)

        button.setTitleColor(greyLighten10(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.titleLabel?.font = WPFontManager.systemRegularFontOfSize(fontSize)

        button.setImage(UIImage(named: "icon-reader-follow"), forState: .Normal)
        button.setImage(UIImage(named: "icon-reader-follow-highlight"), forState: .Highlighted)
    }

    public class func applyReaderSiteStreamDescriptionStyle(label:UILabel) {
        let fontSize = Cards.contentFontSize
        label.font = WPFontManager.merriweatherRegularFontOfSize(fontSize)
        label.textColor = darkGrey()
    }

    public class func applyReaderSiteStreamCountStyle(label:UILabel) {
        let fontSize:CGFloat = 12.0
        label.font = WPFontManager.systemRegularFontOfSize(fontSize)
        label.textColor = grey()
    }


    // MARK: - Gap Marker Styles

    public class func applyGapMarkerButtonStyle(button:UIButton) {
        let normalImage = UIImage(color: WPStyleGuide.greyDarken10(), havingSize: button.bounds.size)
        let highlightedImage = UIImage(color: WPStyleGuide.lightBlue(), havingSize: button.bounds.size)
        button.setBackgroundImage(normalImage, forState: .Normal)
        button.setBackgroundImage(highlightedImage, forState: .Highlighted)

        button.titleLabel?.font = WPFontManager.systemSemiBoldFontOfSize(Cards.loadMoreButtonFontSize)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }


    // MARK: - Metrics

    public struct Cards
    {
        public static let defaultLineHeight:CGFloat = UIDevice.isPad() ? 26.0 : 22.0
        public static let titleFontSize:CGFloat = UIDevice.isPad() ? 24.0 : 18.0
        public static let titleLineHeight:CGFloat = UIDevice.isPad() ? 32.0 : 24.0
        public static let contentFontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
        public static let buttonFontSize:CGFloat = 14.0
        public static let subtextFontSize:CGFloat = 12.0
        public static let loadMoreButtonFontSize:CGFloat = 15.0
        public static let crossPostTitleFontSize:CGFloat = 16.0
        public static let crossPostSubtitleFontSize:CGFloat = 13.0
        public static let crossPostLineHeight:CGFloat = 20.0
    }

    public struct Detail
    {
        public static let titleFontSize:CGFloat = UIDevice.isPad() ? 32.0 : 18.0
        public static let titleLineHeight:CGFloat = UIDevice.isPad() ? 40.0 : 24.0
        public static let contentFontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
    }

}
