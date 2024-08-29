import UIKit
import WordPressUI

// MARK: - UI elements
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {

    /// Muriel/iOS navigation color
    @available(*, deprecated, renamed: "secondarySystemGroupedBackground", message: "Use the platform's default instead")
    static var appBarBackground: UIColor {
        .secondarySystemGroupedBackground
    }

    @available(*, deprecated, renamed: "text", message: "Use the platform's default instead")
    static var appBarTint: UIColor {
        .text
    }

    @available(*, deprecated, renamed: "appBarText", message: "Use the platform's default instead")
    static var appBarText: UIColor {
        .text
    }

    @available(*, deprecated, renamed: "secondarySystemGroupedBackground", message: "Use the platform's default instead")
    static var filterBarBackground: UIColor {
        return .secondarySystemGroupedBackground
    }

    @available(*, deprecated, renamed: "text", message: "Use the platform's default instead")
    static var filterBarSelected: UIColor {
        return .text
    }

    @available(*, deprecated, renamed: "text", message: "Use the platform's default instead")
    static var filterBarSelectedText: UIColor {
        return .text
    }

    @available(*, deprecated, renamed: "tabSelected", message: "Use the platform's default instead")
    static var tabSelected: UIColor {
        return .text
    }

    static var statsPrimaryHighlight: UIColor {
        return UIColor(light: muriel(color: MurielColor(name: .pink, shade: .shade30)),
                        dark: muriel(color: MurielColor(name: .pink, shade: .shade60)))
    }

    static var statsSecondaryHighlight: UIColor {
        return UIColor(light: muriel(color: MurielColor(name: .pink, shade: .shade60)),
                       dark: muriel(color: MurielColor(name: .pink, shade: .shade30)))
    }
}
