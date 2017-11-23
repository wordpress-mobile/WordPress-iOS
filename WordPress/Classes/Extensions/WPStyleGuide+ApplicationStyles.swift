import Foundation
import WordPressShared

extension WPStyleGuide {
    @objc public class func navigationBarBackgroundImage() -> UIImage {
        return UIImage(color: WPStyleGuide.wordPressBlue())
    }

    @objc public class func navigationBarBarStyle() -> UIBarStyle {
        return .black
    }

    @objc public class func navigationBarShadowImage() -> UIImage {
        return UIImage(color: UIColor(fromHex: 0x007eb1))
    }
}
