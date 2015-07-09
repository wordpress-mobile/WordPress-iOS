import Foundation


extension WPStyleGuide
{

    // MARK: Original Post/Site Attribution Styles. 

    public class func originalAttributionParagraphAttributes() -> NSDictionary {
        let fontSize:CGFloat = UIDevice.isPad() ? 16.0 : 14.0
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

    public class func originalAttributionLinkAttributes(linkURL:NSURL) -> NSDictionary {
        return [
            NSForegroundColorAttributeName : WPStyleGuide.mediumBlue(),
            NSLinkAttributeName: linkURL,
        ] as NSDictionary
    }

}
