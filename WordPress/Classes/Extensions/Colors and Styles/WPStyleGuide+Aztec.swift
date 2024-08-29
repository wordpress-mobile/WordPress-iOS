import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .secondaryLabel

    static let aztecFormatBarActiveColor: UIColor = AppStyleGuide.primary

    static let aztecFormatBarDisabledColor = AppStyleGuide.neutral(.shade10)

    static let aztecFormatBarDividerColor: UIColor = .separator

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? AppStyleGuide.neutral(.shade0) : AppStyleGuide.neutral(.shade5)
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .systemBackground : AppStyleGuide.neutral(.shade0)
        }
    }
}
