import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .toolbarInactive

    static let aztecFormatBarActiveColor: UIColor = .primary

    static let aztecFormatBarDisabledColor = UIColor.neutral(shade: .shade10)

    static let aztecFormatBarDividerColor: UIColor = .divider

    static let aztecFormatBarBackgroundColor = UIColor.basicBackground

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .neutral(shade: .shade0) : .neutral(shade: .shade5)
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
        button.tintColor = .neutral(shade: .shade20)

        let edgeInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        button.contentEdgeInsets = edgeInsets
    }
}
