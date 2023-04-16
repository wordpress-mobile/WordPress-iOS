import CoreUI
import UIKit

// MARK: - UI elements
extension UIColor {

    /// Muriel/iOS navigation color
    static var appBarBackground: UIColor {
        .secondarySystemGroupedBackground
    }

    static var appBarTint: UIColor {
        .text
    }

    static var lightAppBarTint: UIColor {
        return .text
    }

    static var appBarText: UIColor {
        .text
    }

    static var filterBarBackground: UIColor {
        return .secondarySystemGroupedBackground
    }

    static var filterBarSelected: UIColor {
        return .primary
    }

    static var filterBarSelectedText: UIColor {
        return .text
    }

    static var tabSelected: UIColor {
        return .text
    }

    /// Note: these values are intended to match the iOS defaults
    static var tabUnselected: UIColor = UIColor(
        light: UIColor(hexString: "999999"),
        dark: UIColor(hexString: "757575")
    )

    static var statsPrimaryHighlight: UIColor {
        return UIColor(light: murielPink30, dark: murielPink60)
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: murielPink60, dark: murielPink30)
    }

    static let murielPink30 = muriel(color: MurielColor(name: .pink, shade: .shade30))
    static let murielPink60 = muriel(color: MurielColor(name: .pink, shade: .shade60))
}
