import Foundation


extension WPStyleGuide
{

    // MARK: Original Post/Site Attribution Styles. 

    public class func originalAttributionParagraphAttributes() -> NSDictionary {
        let fontSize = originalAttributionFontSize()
        let font = WPFontManager.openSansRegularFontOfSize(fontSize)

        let lineHeight:CGFloat = UIDevice.isPad() ? 24.0 : 21.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return [
            NSParagraphStyleAttributeName : paragraphStyle,
            NSFontAttributeName : font,
            NSForegroundColorAttributeName: WPStyleGuide.grey(),
        ] as NSDictionary
    }

    public class func siteAttributionParagraphAttributes() -> NSDictionary {
        let attributes = NSMutableDictionary(dictionary: originalAttributionParagraphAttributes())
        attributes.setValue(WPStyleGuide.mediumBlue(), forKey: NSForegroundColorAttributeName)
        return attributes
    }

    public class func originalAttributionFontSize() -> CGFloat {
        return UIDevice.isPad() ? CGFloat(16.0) : CGFloat(14.0)
    }
}
