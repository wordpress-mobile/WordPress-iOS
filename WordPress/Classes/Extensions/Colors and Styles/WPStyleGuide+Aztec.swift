import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .toolbarInactive

    static let aztecFormatBarActiveColor: UIColor = .primary

    static let aztecFormatBarDisabledColor = UIColor.neutral(.shade10)

    static let aztecFormatBarDividerColor: UIColor = .divider

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .neutral(.shade0) : .neutral(.shade5)
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .basicBackground : .neutral(.shade0)
        }
    }
}
