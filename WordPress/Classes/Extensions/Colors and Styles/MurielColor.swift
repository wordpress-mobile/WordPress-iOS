/// Generates the names of the named colors in the ColorPalette.xcasset
@available(*, deprecated, message: "Use AppStyleGuide instead")
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

@available(*, deprecated, message: "Use AppStyleGuide instead")
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
@available(*, deprecated, message: "Use AppStyleGuide instead")
struct MurielColor {
    let name: MurielColorName
    let shade: MurielColorShade
    let assetName: String

    init(name: MurielColorName, shade: MurielColorShade = .shade50) {
        self.name = name
        self.shade = shade
        self.assetName = "\(name)\(shade)"
    }

    init(from identifier: MurielColor, shade: MurielColorShade = .shade50) {
        self.init(name: identifier.name, shade: shade)
    }

    // MARK: - Muriel's semantic colors
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let accent = AppStyleGuide.accent
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let brand = AppStyleGuide.brand
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let divider = AppStyleGuide.divider
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let error = AppStyleGuide.error
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let gray = AppStyleGuide.gray
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let primary = AppStyleGuide.primary
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let success = AppStyleGuide.success
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let text = AppStyleGuide.text
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let textSubtle = AppStyleGuide.textSubtle
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let warning = AppStyleGuide.warning
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let jetpackGreen = AppStyleGuide.jetpackGreen
    @available(*, deprecated, message: "Use AppStyleGuide instead")
    static let editorPrimary = AppStyleGuide.editorPrimary

    var color: UIColor {
        let color = UIColor(named: assetName)

        guard let unwrappedColor = color else {
            preconditionFailure("Invalid color: \(assetName)")
        }

        return unwrappedColor
    }
}
