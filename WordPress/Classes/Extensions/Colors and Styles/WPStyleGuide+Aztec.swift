import UIKit
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .secondaryLabel

    static let aztecFormatBarActiveColor: UIColor = UIAppColor.primary

    static let aztecFormatBarDisabledColor = UIAppColor.neutral(.shade10)

    static let aztecFormatBarDividerColor: UIColor = .separator

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? UIAppColor.neutral(.shade0) : UIAppColor.neutral(.shade5)
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .systemBackground : UIAppColor.neutral(.shade0)
        }
    }
}
