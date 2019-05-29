/// Generates the names of the named colors in the ColorPalette.xcasset
enum MurielColorName: String {
    // MARK: - Base colors
    case blue
    case celadon
    case gray
    case green
    case hotBlue = "Hot-Blue"
    case hotGreen = "Hot-Green"
    case hotOrange = "Hot-Orange"
    case hotPink = "Hot-Pink"
    case hotPurple = "Hot-Purple"
    case hotRed = "Hot-Red"
    case hotYellow = "Hot-Yellow"
    case jetpackGreen = "Jetpack-Green"
    case orange
    case pink
    case purple
    case red
    case wooPurple = "Woo-Purple"
    case yellow
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum MurielColorShade: Int {
    case shade0 = 0
    case shade50 = 50
    case shade100 = 100
    case shade200 = 200
    case shade300 = 300
    case shade400 = 400
    case shade500 = 500
    case shade600 = 600
    case shade700 = 700
    case shade800 = 800
    case shade900 = 900
}

struct MurielColorIdentifier {
    let name: MurielColorName
    let shade: MurielColorShade

    init(name: MurielColorName, shade: MurielColorShade = .shade500) {
        self.name = name
        self.shade = shade
    }

    // MARK: - Semantic colors
    static let accent = MurielColorIdentifier.init(name: MurielColorName.hotPink)
    static let divider = MurielColorIdentifier.init(name: MurielColorName.gray, shade: .shade50)
    static let error = MurielColorIdentifier.init(name: MurielColorName.hotRed)
    static let neutral = MurielColorIdentifier.init(name: MurielColorName.gray)
    static let primary = MurielColorIdentifier.init(name: MurielColorName.blue)
    static let success = MurielColorIdentifier.init(name: MurielColorName.green)
    static let text = MurielColorIdentifier.init(name: MurielColorName.gray, shade: .shade800)
    static let textSubtle = MurielColorIdentifier.init(name: MurielColorName.gray, shade: .shade500)
    static let warning = MurielColorIdentifier.init(name: MurielColorName.hotYellow)

    /// The full name of the color, with required shade value
    func name(with shade: MurielColorShade = .shade500) -> String {
        return "\(self)-\(shade.rawValue)"
    }
}

extension UIColor {
    /// Get a UIColor from the Muriel color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a MurielColorIdentifier
    ///   - shade: an optional shade value
    /// - Returns: UIColor. Red in cases of error
    class func muriel(color: MurielColorIdentifier, shade: MurielColorShade = .shade500) -> UIColor {
        return UIColor(named: color.name(with: shade)) ?? .red
    }


    /// Muriel accent color
    static var accent = muriel(color: .accent)
    class func accent(shade: MurielColorShade) -> UIColor {
        return muriel(color: .accent, shade: shade)
    }

    /// Muriel divider color
    static var divider = muriel(color: .divider)

    /// Muriel error color
    static var error = muriel(color: .error)
    class func error(shade: MurielColorShade) -> UIColor {
        return muriel(color: .error, shade: shade)
    }

    /// Muriel neutral color
    static var neutral = muriel(color: .neutral)
    class func neutral(shade: MurielColorShade) -> UIColor {
        return muriel(color: .neutral, shade: shade)
    }

    /// Muriel primary color
    static var primary = muriel(color: .primary)
    class func primary(shade: MurielColorShade) -> UIColor {
        return muriel(color: .primary, shade: shade)
    }

    /// Muriel success color
    static var success = muriel(color: .success)
    class func success(shade: MurielColorShade) -> UIColor {
        return muriel(color: .success, shade: shade)
    }

    /// Muriel text color
    static var text = muriel(color: .text)
    class func text(shade: MurielColorShade) -> UIColor {
        return muriel(color: .text, shade: shade)
    }

    /// Muriel text subtle color
    static var textSubtle = muriel(color: .textSubtle)
    class func textSubtle(shade: MurielColorShade) -> UIColor {
        return muriel(color: .textSubtle, shade: shade)
    }

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(shade: MurielColorShade) -> UIColor {
        return muriel(color: .warning, shade: shade)
    }
}
