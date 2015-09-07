import Foundation

/**
    A WPStyleGuide extension with styles and methods specific to the
    Reader feature.
*/
extension WPStyleGuide
{

    // MARK: Original Post/Site Attribution Styles. 

    public class func originalAttributionParagraphAttributes() -> [NSObject: AnyObject] {
        let fontSize = originalAttributionFontSize()
        let font = WPFontManager.openSansRegularFontOfSize(fontSize)

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

    public class func siteAttributionParagraphAttributes() -> [NSObject: AnyObject] {
        let attributes = NSMutableDictionary(dictionary: originalAttributionParagraphAttributes())
        attributes.setValue(mediumBlue(), forKey: NSForegroundColorAttributeName)
        return attributes as [NSObject: AnyObject]
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

    public class func readerCardTitleAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.titleFontSize
        let font = WPFontManager.merriweatherBoldFontOfSize(fontSize)

        let lineHeight = Cards.titleLineHeight
        var paragraphStyle = NSMutableParagraphStyle()
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
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardWordCountAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.openSansRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: greyLighten10()
        ]
    }

    public class func readerCardReadingTimeAttributes() -> [NSObject: AnyObject] {
        let fontSize:CGFloat = UIDevice.isPad() ? 14.0 : 12.0
        let font = WPFontManager.openSansRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: greyLighten10()
        ]
    }


    // MARK: - Stream Header Attributed Text Attributes

    public class func readerStreamHeaderDescriptionAttributes() -> [NSObject: AnyObject] {
        let fontSize = Cards.contentFontSize
        let font = WPFontManager.merriweatherRegularFontOfSize(fontSize)

        let lineHeight = Cards.defaultLineHeight
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }


    // MARK: - Apply Card Styles

    public class func applyReaderCardSiteButtonStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.titleLabel!.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        button.setTitleColor(mediumBlue(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.setTitleColor(greyDarken20(), forState: .Disabled)
    }

    public class func applyReaderCardBylineLabelStyle(label:UILabel) {
        let fontSize:CGFloat = 12.0
        label.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        label.textColor = grey()
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
        button.titleLabel?.font = WPFontManager.openSansRegularFontOfSize(fontSize)
    }

    public class func applyReaderCardActionButtonStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.setTitleColor(grey(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.titleLabel?.font = WPFontManager.openSansRegularFontOfSize(fontSize)
    }


    // MARK: - Apply Stream Header Styles

    public class func applyReaderStreamHeaderTitleStyle(label:UILabel) {
        let fontSize:CGFloat = 14.0
        label.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        label.textColor = grey()
    }

    public class func applyReaderStreamHeaderDetailStyle(label:UILabel) {
        let fontSize:CGFloat = 12.0
        label.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        label.textColor = grey()
    }

    public class func applyReaderStreamHeaderFollowingStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        let title = NSLocalizedString("Following", comment: "Gerund. A button label indicating the user is currently subscribed to a topic or site in ther eader. Tapping unsubscribes the user.")

        button.setTitle(title, forState: .Normal)
        button.setTitle(title, forState: .Highlighted)

        button.setTitleColor(validGreen(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
        button.titleLabel?.font = WPFontManager.openSansRegularFontOfSize(fontSize)

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
        button.titleLabel?.font = WPFontManager.openSansRegularFontOfSize(fontSize)

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
        label.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        label.textColor = grey()
    }


    // MARK: - Metrics

    public struct Cards
    {
        public static let defaultLineHeight:CGFloat = UIDevice.isPad() ? 24.0 : 21.0
        public static let titleFontSize:CGFloat = UIDevice.isPad() ? 24.0 : 16.0
        public static let titleLineHeight:CGFloat = UIDevice.isPad() ? 32.0 : 21.0
        public static let contentFontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
        public static let buttonFontSize:CGFloat = 14.0
    }

}
