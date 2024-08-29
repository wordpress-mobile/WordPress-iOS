import UIKit
import WordPressUI

// MARK: - UI elements
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {

    /// Muriel/iOS navigation color
    @available(*, deprecated, renamed: "primary", message: "Use the platform's default instead")
    static var appBarTint: UIColor {
        .primary
    }

    @available(*, deprecated, renamed: "text", message: "Use the platform's default instead")
    static var appBarText: UIColor {
        .text
    }

    @available(*, deprecated, renamed: "label", message: "Use the platform's default instead")
    static var filterBarSelected: UIColor {
        .label
    }

    @available(*, deprecated, renamed: "label", message: "Use the platform's default instead")
    static var filterBarSelectedText: UIColor {
        .label
    }

    @available(*, deprecated, renamed: "primary", message: "Use the platform's default instead")
    static var tabSelected: UIColor {
        return .primary
    }
}
