import UIKit
import Gridicons
import WordPressShared

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .secondaryLabel

    static let aztecFormatBarActiveColor: UIColor = AppColor.primary

    static let aztecFormatBarDisabledColor = AppColor.neutral(.shade10)

    static let aztecFormatBarDividerColor: UIColor = .separator

    static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? AppColor.neutral(.shade0) : AppColor.neutral(.shade5)
        }
    }

    static var aztecFormatPickerBackgroundColor: UIColor {
        get {
            return (UIDevice.isPad()) ? .systemBackground : AppColor.neutral(.shade0)
        }
    }
}
