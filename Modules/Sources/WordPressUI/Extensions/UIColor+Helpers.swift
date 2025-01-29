import UIKit

public extension UIColor {

    // A way to create dynamic colors that's compatible with iOS 11 & 12
    @objc
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
    }

    convenience init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Creates a color based on a hexString. If the string is not a valid hexColor it return nil
    /// Example of colors: #FF0000, #00FF0000
    ///
    /// This method should only be used for parsing colors from third-party content  – if you're defining a color in code, use `fromHex`
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        guard let int = Scanner(string: hex).scanUInt64(representation: .hexadecimal) else {
            return nil
        }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)

    }

    convenience init(fromHex hex: UInt32) {
        self.init(
            red: CGFloat(UInt8((hex & 0xFF0000) >> 16)) / 0xFF,
            green: CGFloat(UInt8((hex & 0xFF00) >> 8)) / 0xFF,
            blue: CGFloat(UInt8(hex & 0xFF)) / 0xFF,
            alpha: 1.0
        )
    }

    convenience init(fromHex hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat(UInt8((hex & 0xFF0000) >> 16)) / 0xFF,
            green: CGFloat(UInt8((hex & 0xFF00) >> 8)) / 0xFF,
            blue: CGFloat(UInt8(hex & 0xFF)) / 0xFF,
            alpha: alpha
        )
    }

    /// Produces an 6-digit CSS color hex string representation of `UIColor`.
    var hexString: String {
        guard let components = self.cgColor.components else {
            preconditionFailure("Color can't be represented in hexadecimal form")
        }

        if components.count == 2 {
            let w = Float(components[0])
            return String(format: "%02lX%02lX%02lX", lroundf(w * 255), lroundf(w * 255), lroundf(w * 255))
        }

        if components.count == 4 {
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])

            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }

        preconditionFailure("Color can't be represented in hexadecimal form")
    }

    /// Produces an 8-digit CSS color hex string representation of `UIColor`.
    /// The last two digits represent the alpha value of the color.
    var hexStringWithAlpha: String {
        guard let components = self.cgColor.components else {
            preconditionFailure("Color can't be represented in hexadecimal form")
        }

        if components.count == 2 {
            let w = Float(components[0])
            let a = Float(components[1])

            return String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(w * 255),
                lroundf(w * 255),
                lroundf(w * 255),
                lroundf(a * 255)
            )
        }

        if components.count == 4 {
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            let a = Float(components[3])

            return String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255),
                lroundf(a * 255)
            )
        }

        preconditionFailure("Color can't be represented in hexadecimal form")
    }

    // MARK: - Traits

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
        UIColor(light: darkVariant(), dark: lightVariant())
    }
}
