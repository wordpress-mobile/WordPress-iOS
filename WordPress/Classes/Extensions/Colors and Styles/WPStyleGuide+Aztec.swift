import UIKit
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    static let aztecFormatBarInactiveColor: UIColor = .secondaryLabel

    static let aztecFormatBarActiveColor: UIColor = UIAppColor.primary

    static let aztecFormatBarDisabledColor = UIAppColor.neutral(.shade10)

    static let aztecFormatBarDividerColor: UIColor = .separator

    /// The format picker is a popover on the pad idiom and a sheet elsewhere, so its background
    /// follows the idiom of the presenting view controller.
    static func aztecFormatPickerSelectedCellBackgroundColor(for traitCollection: UITraitCollection) -> UIColor {
        (traitCollection.userInterfaceIdiom == .pad) ? UIAppColor.neutral(.shade0) : UIAppColor.neutral(.shade5)
    }

    static func aztecFormatPickerBackgroundColor(for traitCollection: UITraitCollection) -> UIColor {
        (traitCollection.userInterfaceIdiom == .pad) ? .systemBackground : UIAppColor.neutral(.shade0)
    }
}
