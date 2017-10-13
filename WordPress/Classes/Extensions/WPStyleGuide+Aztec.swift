import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = UIColor(hexString: "7B9AB1")

    static let aztecFormatBarActiveColor: UIColor = UIColor(hexString: "11181D")

    static let aztecFormatBarDisabledColor = WPStyleGuide.greyLighten20()

    static let aztecFormatBarDividerColor = WPStyleGuide.greyLighten30()

    static let aztecFormatBarBackgroundColor = UIColor.white

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? WPStyleGuide.lightGrey() : WPStyleGuide.greyLighten30()
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .white : WPStyleGuide.lightGrey()
        }
    }

    static func configureBetaButton(_ button: UIButton) {
        let helpImage = Gridicon.iconOfType(.helpOutline)
        button.setImage(helpImage, for: .normal)
        button.tintColor = WPStyleGuide.greyLighten10()

        let edgeInsets = UIEdgeInsets(top: 6.0, left: 8.0, bottom: 6.0, right: 8.0)
        button.contentEdgeInsets = edgeInsets
    }
}
