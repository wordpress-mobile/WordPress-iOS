import UIKit
import WordPressUI

// MARK: - UI elements
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {

    /// Muriel/iOS navigation color
    static var appBarBackground: UIColor {
        UIColor(light: .white, dark: .gray(.shade100))
    }

    @available(*, deprecated, renamed: "primary", message: "Use the platform's default instead")
    static var appBarTint: UIColor {
        .primary
    }

    @available(*, deprecated, renamed: "text", message: "Use the platform's default instead")
    static var appBarText: UIColor {
        .text
    }

    static var filterBarBackground: UIColor {
        return UIColor(light: .white, dark: .gray(.shade100))
    }

    static var filterBarSelected: UIColor {
        return UIColor(light: .primary, dark: .label)
    }

    static var filterBarSelectedText: UIColor {
        return UIColor(light: .primary, dark: .label)
    }

    static var tabSelected: UIColor {
        return .primary
    }

    /// Note: these values are intended to match the iOS defaults
    static var tabUnselected: UIColor =  UIColor(light: UIColor(fromHex: 0x999999), dark: UIColor(fromHex: 0x757575))

    static var statsPrimaryHighlight: UIColor {
        return  UIColor(light: AppStyleGuide.accent(.shade30), dark: AppStyleGuide.accent(.shade60))
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: AppStyleGuide.accent(.shade60), dark: AppStyleGuide.accent(.shade30))
    }
}
