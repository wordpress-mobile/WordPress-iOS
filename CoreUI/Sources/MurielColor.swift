/// A specific color and shade from the muriel palette's asset file
public struct MurielColor {

    /// Generates the names of the named colors in the ColorPalette.xcasset
    public enum Name: String, CustomStringConvertible {
        case wordPressBlue
        case blue
        case celadon
        case gray
        case green
        case orange
        case pink
        case purple
        case red
        case yellow
        case jetpackGreen

        public var description: String {
            // can't use .capitalized because it lowercases the P and B in "wordPressBlue"
            return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    /// Value of a Muriel color's shade
    ///
    /// Note: There are a finite number of acceptable values. Not just any `Int` works.
    ///       Also, `enum` cases cannot begin with a number, thus the `shade` prefix.
    public enum Shade: Int, CustomStringConvertible {
        case shade0 = 0
        case shade5 = 5
        case shade10 = 10
        case shade20 = 20
        case shade30 = 30
        case shade40 = 40
        case shade50 = 50
        case shade60 = 60
        case shade70 = 70
        case shade80 = 80
        case shade90 = 90
        case shade100 = 100

        public var description: String {
            return "\(rawValue)"
        }
    }

    public let name: Name
    public let shade: Shade

    public init(name: Name, shade: Shade = .shade50) {
        self.name = name
        self.shade = shade
    }

    public init(from identifier: MurielColor, shade: Shade) {
        self.name = identifier.name
        self.shade = shade
    }

    /// The full name of the color, with required shade value
    public func assetName() -> String {
        return "\(name)\(shade)"
    }
}
