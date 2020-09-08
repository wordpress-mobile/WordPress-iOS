import Foundation

extension CGFloat {
    static func interpolated(from fromValue: CGFloat, to toValue: CGFloat, progress: CGFloat) -> CGFloat {
        return fromValue.interpolated(to: toValue, with: progress)
    }

    /// Interpolates a CGFloat
    /// - Parameters:
    ///   - toValue: The to value
    ///   - progress: a number between 0.0 and 1.0
    /// - Returns: a new CGFloat value between 2 numbers using the progress
    func interpolated(to toValue: CGFloat, with progress: CGFloat) -> CGFloat {
        return (1 - progress) * self + progress * toValue
    }
}

extension UIColor {
    struct RGBAComponents {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        func interpolated(to toColor: RGBAComponents, with progress: CGFloat) -> RGBAComponents {
            return RGBAComponents(red: red.interpolated(to: toColor.red, with: progress),
                                  green: green.interpolated(to: toColor.green, with: progress),
                                  blue: blue.interpolated(to: toColor.blue, with: progress),
                                  alpha: alpha.interpolated(to: toColor.alpha, with: progress))
        }
    }

    /// Returns the RGBA components for a color
    var rgbaComponents: RGBAComponents {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return RGBAComponents(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Interpolates between the fromColor and toColor using the given progress
    /// - Parameters:
    ///   - fromColor: The start color
    ///   - toColor: The start color
    ///   - progress: A value between 0.0 and 1.0
    /// - Returns: An
    static func interpolate(from fromColor: UIColor, to toColor: UIColor, with progress: CGFloat) -> UIColor {

        if fromColor == toColor {
            return fromColor
        }

        let components = fromColor.rgbaComponents.interpolated(to: toColor.rgbaComponents, with: progress)

        return UIColor(red: components.red,
                       green: components.green,
                       blue: components.blue,
                       alpha: components.alpha)
    }
}
