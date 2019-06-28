import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = UIColor(hexString: "7B9AB1")

    static let aztecFormatBarActiveColor: UIColor = UIColor(hexString: "11181D")

    static let aztecFormatBarDisabledColor = UIColor.neutral(shade: .shade100)

    static let aztecFormatBarDividerColor = UIColor.neutral(shade: .shade50)

    static let aztecFormatBarBackgroundColor = UIColor.white

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .neutral(shade: .shade0) : .neutral(shade: .shade50)
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .white : .neutral(shade: .shade0)
        }
    }

    static func configureBetaButton(_ button: UIButton) {
        let helpImage = Gridicon.iconOfType(.helpOutline)
        button.setImage(helpImage, for: .normal)
        button.tintColor = .neutral(shade: .shade200)

        let edgeInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        button.contentEdgeInsets = edgeInsets
    }
}
