import UIKit
import WordPressUI

// MARK: - UI elements
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {

    static let statsPrimaryHighlight = UIColor(
        light: AppColor.pink(.shade30),
        dark: AppColor.pink(.shade60)
    )

    static let statsSecondaryHighlight = UIColor(
        light: AppColor.pink(.shade60),
        dark: AppColor.pink(.shade30)
    )
}
