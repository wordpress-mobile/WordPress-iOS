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

        let lineHeight:CGFloat = UIDevice.isPad() ? 24.0 : 21.0
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
        return UIDevice.isPad() ? 16.0 : 14.0
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
        let fontSize:CGFloat = UIDevice.isPad() ? 24.0 : 16.0
        let font = WPFontManager.merriweatherBoldFontOfSize(fontSize)

        let lineHeight:CGFloat = UIDevice.isPad() ? 32.0 : 21.0
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }

    public class func readerCardSummaryAttributes() -> [NSObject: AnyObject] {
        let fontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
        let font = WPFontManager.merriweatherLightFontOfSize(fontSize)

        let lineHeight:CGFloat = UIDevice.isPad() ? 24.0 : 21.0
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return [
            NSParagraphStyleAttributeName: paragraphStyle,
            NSFontAttributeName: font
        ]
    }


    // MARK: - Apply Styles

    public class func applyReaderCardSiteLabelStyle(label:UILabel) {
        let fontSize:CGFloat = 14.0
        label.font = WPFontManager.openSansRegularFontOfSize(fontSize)
        label.textColor = greyDarken20()
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

    public class func applyReaderCardActionButtonStyle(button:UIButton) {
        let fontSize:CGFloat = 14.0
        button.setTitleColor(grey(), forState: .Normal)
        button.titleLabel?.font = WPFontManager.openSansRegularFontOfSize(fontSize)
    }

}
