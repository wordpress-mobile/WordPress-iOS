import Foundation
import WordPressShared

extension WPStyleGuide
{
    public class func navigationBarBackgroundImage() -> UIImage {
        return UIImage(color: WPStyleGuide.wordPressBlue())
    }

    public class func navigationBarBarStyle() -> UIBarStyle {
        return .Black
    }

    public class func navigationBarShadowImage() -> UIImage {
        return UIImage(color: UIColor(fromHex: 0x007eb1))
    }
}
