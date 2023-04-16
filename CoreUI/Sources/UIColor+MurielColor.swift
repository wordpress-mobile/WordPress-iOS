import CoreUI

public extension UIColor {

    /// Get a `UIColor` from the Muriel color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a `MurielColor`
    /// - Returns: `UIColor`. Red in cases of error
    static func muriel(color murielColor: MurielColor) -> UIColor {
        let assetName = murielColor.assetName()
        let color = UIColor(named: assetName)

        guard let unwrappedColor = color else {
            return .red
        }

        return unwrappedColor
    }

    /// Get a `UIColor` from the Muriel color palette, adjusted to a given shade
    ///
    /// - Parameter color: an instance of a `MurielColor`
    /// - Parameter shade: a `MurielColor`.Shade
    static func muriel(color: MurielColor, _ shade: MurielColor.Shade) -> UIColor {
        let newColor = MurielColor(from: color, shade: shade)
        return muriel(color: newColor)
    }

    /// Get a `UIColor` from the Muriel color palette by name, adjusted to a given shade
    ///
    /// - Parameters:
    ///   - name: a `MurielColor`.Name
    ///   - shade: a `MurielColor`.Shade
    /// - Returns: the desired color/shade
    static func muriel(name: MurielColor.Name, _ shade: MurielColor.Shade) -> UIColor {
        let newColor = MurielColor(name: name, shade: shade)
        return muriel(color: newColor)
    }
}
