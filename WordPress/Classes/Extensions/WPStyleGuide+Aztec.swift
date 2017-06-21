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
