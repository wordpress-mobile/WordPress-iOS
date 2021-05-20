/// Generates the names of the named colors in the ColorPalette.xcasset
enum MurielColorName: String, CustomStringConvertible {
    // MARK: - Base colors
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

    var description: String {
        // can't use .capitalized because it lowercases the P and B in "wordPressBlue"
        return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum MurielColorShade: Int, CustomStringConvertible {
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

    var description: String {
        return "\(rawValue)"
    }
}

/// A specific color and shade from the muriel palette's asset file
struct MurielColor {
    let name: MurielColorName
    let shade: MurielColorShade

    init(name: MurielColorName, shade: MurielColorShade = .shade50) {
        self.name = name
        self.shade = shade
    }

    init(from identifier: MurielColor, shade: MurielColorShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Muriel's semantic colors
    static let accent = AppStyleGuide.accent
    static let brand = AppStyleGuide.brand
    static let divider = AppStyleGuide.divider
    static let error = AppStyleGuide.error
    static let gray = AppStyleGuide.gray
    static let primary = AppStyleGuide.primary
    static let success = AppStyleGuide.success
    static let text = AppStyleGuide.text
    static let textSubtle = AppStyleGuide.textSubtle
    static let warning = AppStyleGuide.warning
    static let jetpackGreen = AppStyleGuide.jetpackGreen

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)\(shade)"
    }
}
