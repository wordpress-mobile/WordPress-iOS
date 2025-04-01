import UIKit
import WordPressUI

/// Objective-C *only* API for the Muriel colors
@objc extension UIColor {

    @available(swift, obsoleted: 1.0)
    public static func murielPrimary() -> UIColor {
        return UIAppColor.primary
    }

    @available(swift, obsoleted: 1.0)
    public static func murielPrimary40() -> UIColor {
        return UIAppColor.primary(.shade40)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielPrimaryDark() -> UIColor {
        return UIAppColor.primaryDark
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral() -> UIColor {
        return UIAppColor.neutral
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral0() -> UIColor {
        return UIAppColor.neutral(.shade0)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral5() -> UIColor {
        return UIAppColor.neutral(.shade5)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral10() -> UIColor {
        return UIAppColor.neutral(.shade10)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral20() -> UIColor {
        return UIAppColor.neutral(.shade20)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral30() -> UIColor {
        return UIAppColor.neutral(.shade30)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral40() -> UIColor {
        return UIAppColor.neutral(.shade40)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral60() -> UIColor {
        return UIAppColor.neutral(.shade60)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielNeutral70() -> UIColor {
        return UIAppColor.neutral(.shade70)
    }

    @available(swift, obsoleted: 1.0)
    public static func murielSuccess() -> UIColor {
        return UIAppColor.success
    }

    @available(swift, obsoleted: 1.0)
    public static func murielText() -> UIColor {
        return .label
    }

    @available(swift, obsoleted: 1.0)
    public static func murielTextSubtle() -> UIColor {
        return .secondaryLabel
    }

    @available(swift, obsoleted: 1.0)
    public static func murielTextTertiary() -> UIColor {
        return .tertiaryLabel
    }

    @available(swift, obsoleted: 1.0)
    public static func murielError() -> UIColor {
        return UIAppColor.error
    }

    @available(swift, obsoleted: 1.0)
    public static func murielBasicBackground() -> UIColor {
        return .systemBackground
    }

    @available(swift, obsoleted: 1.0)
    public static func murielTextPlaceholder() -> UIColor {
        return .tertiaryLabel
    }

    @available(swift, obsoleted: 1.0)
    public static func murielListForeground() -> UIColor {
        return .secondarySystemGroupedBackground
    }

    @available(swift, obsoleted: 1.0)
    public static func murielListBackground() -> UIColor {
        return .systemGroupedBackground
    }

    @available(swift, obsoleted: 1.0)
    public static func murielListIcon() -> UIColor {
        return .secondaryLabel
    }

    @available(swift, obsoleted: 1.0)
    public static func murielAppBarText() -> UIColor {
        return UIAppColor.appBarText
    }

    @available(swift, obsoleted: 1.0)
    public static func murielAppBarBackground() -> UIColor {
        return UIAppColor.appBarTint
    }
}
