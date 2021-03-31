import UIKit

// MARK: - UI elements
extension UIColor {

    /// Muriel/iOS navigation color
    static var appBarBackground: UIColor {
        if FeatureFlag.newNavBarAppearance.enabled {
            return .secondarySystemGroupedBackground
        }

        return UIColor(light: .brand, dark: .gray(.shade100))
    }

    static var appBarTint: UIColor {
        if FeatureFlag.newNavBarAppearance.enabled {
            return .primary
        }

        return .white
    }

    static var appBarText: UIColor {
        if FeatureFlag.newNavBarAppearance.enabled {
            return .text
        }

        return .white
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

    static var statsPrimaryBar: UIColor {
        return UIColor(light: .primaryLight, dark: .primary(.shade80))
    }

    static var statsSecondaryBar: UIColor {
        return UIColor(light: .primary(.shade60), dark: .primary)
    }

    static var statsPrimaryHighlight: UIColor {
        return  UIColor(light: .accent(.shade30), dark: .accent(.shade60))
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: .accent(.shade60), dark: .accent(.shade30))
    }
}
