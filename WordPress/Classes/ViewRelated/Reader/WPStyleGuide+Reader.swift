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

    public class func siteAttributionParagraphAttributes() -> NSDictionary {
        let attributes = NSMutableDictionary(dictionary: originalAttributionParagraphAttributes())
        attributes.setValue(mediumBlue(), forKey: NSForegroundColorAttributeName)
        return attributes
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

    // MARK: - Attributed Text Attributes

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


    // MARK: - Apply Styles

    public class func applyReaderCardSiteButtonActiveStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.titleLabel!.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        button.setTitleColor(mediumBlue(), forState: .Normal)
        button.setTitleColor(lightBlue(), forState: .Highlighted)
    }

    public class func applyReaderCardSiteButtonInactiveStyle(button:UIButton) {
        let fontSize = Cards.buttonFontSize
        button.titleLabel!.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        button.setTitleColor(greyDarken20(), forState: .Normal)
        button.setTitleColor(greyDarken20(), forState: .Highlighted)
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

    public struct Cards
    {
        public static let defaultLineHeight:CGFloat = UIDevice.isPad() ? 24.0 : 21.0
        public static let titleFontSize:CGFloat = UIDevice.isPad() ? 24.0 : 16.0
        public static let titleLineHeight:CGFloat = UIDevice.isPad() ? 32.0 : 21.0
        public static let contentFontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
        public static let buttonFontSize:CGFloat = 14.0
    }

}
