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
        return UIColor(light: .white, dark: .gray(.shade100))
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
    static var tabUnselected: UIColor =  UIColor(light: UIColor(hexString: "999999"), dark: UIColor(hexString: "757575"))

    static var statsPrimaryHighlight: UIColor {
        return  UIColor(light: muriel(color: MurielColor(name: .pink, shade: .shade30)),
                        dark: muriel(color: MurielColor(name: .pink, shade: .shade60)))
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: muriel(color: MurielColor(name: .pink, shade: .shade60)),
                       dark: muriel(color: MurielColor(name: .pink, shade: .shade30)))
    }
}
