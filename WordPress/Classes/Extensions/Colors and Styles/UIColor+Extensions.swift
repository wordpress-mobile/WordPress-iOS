import Foundation
import WordPressUI

@objc
extension UIColor {

    convenience init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    func color(for trait: UITraitCollection?) -> UIColor {
        if let trait {
            return resolvedColor(with: trait)
        }
        return self
    }

    func lightVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .light))
    }

    func darkVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .dark))
    }

    /// The same color with the dark and light variants swapped
    var variantInverted: UIColor {
        UIColor(light: self.darkVariant(), dark: self.lightVariant())
    }
}
