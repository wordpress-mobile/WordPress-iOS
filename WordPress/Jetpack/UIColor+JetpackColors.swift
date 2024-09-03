import UIKit
import WordPressUI

// MARK: - UI elements
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {

    static let statsPrimaryHighlight = UIColor(
        light: AppStyleGuide.pink(.shade30),
        dark: AppStyleGuide.pink(.shade60)
    )

    static let statsSecondaryHighlight = UIColor(
        light: AppStyleGuide.pink(.shade60),
        dark: AppStyleGuide.pink(.shade30)
    )
}
