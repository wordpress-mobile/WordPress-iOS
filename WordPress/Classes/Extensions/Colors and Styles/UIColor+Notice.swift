import UIKit
import WordPressUI

extension UIColor {

    static var invertedLabel: UIColor {
        UIColor(
            light: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .dark)),
            dark: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .light))
        )
    }
}
