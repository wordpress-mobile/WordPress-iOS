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
}
