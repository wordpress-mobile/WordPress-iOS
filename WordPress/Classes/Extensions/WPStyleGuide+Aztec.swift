import UIKit
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor = UIColor(hexString: "7B9AB1")

    static let aztecFormatBarActiveColor = WPStyleGuide.wordPressBlue()

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
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11.0)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 3.0

        button.tintColor = WPStyleGuide.darkGrey()
        button.setTitleColor(WPStyleGuide.darkGrey(), for: .disabled)
        button.layer.borderColor = WPStyleGuide.greyLighten20().cgColor

        let verticalInset = CGFloat(6.0)
        let horizontalInset = CGFloat(8.0)
        button.contentEdgeInsets = UIEdgeInsets(top: verticalInset,
                                                left: horizontalInset,
                                                bottom: verticalInset,
                                                right: horizontalInset)
    }
}
