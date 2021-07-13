import UIKit

// MARK: - UI elements
extension UIColor {

    /// Muriel/iOS navigation color
    static var appBarBackground: UIColor {
        UIColor(light: .white, dark: .gray(.shade100))
    }

    static var appBarTint: UIColor {
        .primary
    }

    static var lightAppBarTint: UIColor {
        return UIColor(light: .primary, dark: .white)
    }

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
    static var tabUnselected: UIColor =  UIColor(light: UIColor(hexString: "999999"), dark: UIColor(hexString: "757575"))

    static var statsPrimaryHighlight: UIColor {
        return  UIColor(light: .accent(.shade30), dark: .accent(.shade60))
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: .accent(.shade60), dark: .accent(.shade30))
    }
}
