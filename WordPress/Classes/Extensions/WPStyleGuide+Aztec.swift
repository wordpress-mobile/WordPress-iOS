import UIKit
import WordPressShared

extension WPStyleGuide {
    static var aztecFormatBarInactiveColor: UIColor {
        return UIColor(hexString: "7B9AB1")
    }

    static var aztecFormatBarActiveColor: UIColor {
        return WPStyleGuide.darkGrey()
    }

    static var aztecFormatBarDisabledColor: UIColor {
        return WPStyleGuide.greyLighten20()
    }

    static var aztecFormatBarBackgroundColor: UIColor {
        return .white
    }
}
