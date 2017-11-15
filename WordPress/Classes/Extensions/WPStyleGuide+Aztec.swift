import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    @objc static let aztecFormatBarInactiveColor: UIColor = UIColor(hexString: "7B9AB1")

    @objc static let aztecFormatBarActiveColor: UIColor = UIColor(hexString: "11181D")

    @objc static let aztecFormatBarDisabledColor = WPStyleGuide.greyLighten20()

    @objc static let aztecFormatBarDividerColor = WPStyleGuide.greyLighten30()

    @objc static let aztecFormatBarBackgroundColor = UIColor.white

    @objc static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? WPStyleGuide.lightGrey() : WPStyleGuide.greyLighten30()
        }
    }

    @objc static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .white : WPStyleGuide.lightGrey()
        }
    }

    @objc static func configureBetaButton(_ button: UIButton) {
        let helpImage = Gridicon.iconOfType(.helpOutline)
        button.setImage(helpImage, for: .normal)
        button.tintColor = WPStyleGuide.greyLighten10()

        let edgeInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        button.contentEdgeInsets = edgeInsets
    }
}
