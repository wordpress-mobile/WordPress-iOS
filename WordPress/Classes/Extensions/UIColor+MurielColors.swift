/// Only necessary until the .murielColors feature flag is removed
import WordPressShared

/// Generates the names of the named colors in the ColorPalette.xcasset
enum MurielColorName: String, CustomStringConvertible {
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

    var description: String {
        return rawValue.capitalized
    }
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum MurielColorShade: Int, CustomStringConvertible {
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

    var description: String {
        return "\(rawValue)"
    }
}

struct MurielColor {
    let name: MurielColorName
    let shade: MurielColorShade

    init(name: MurielColorName, shade: MurielColorShade = .shade500) {
        self.name = name
        self.shade = shade
    }

    init(from identifier: MurielColor, shade: MurielColorShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Muriel's semantic colors
    static let accent = MurielColor(name: .hotPink)
    static let divider = MurielColor(name: .gray, shade: .shade50)
    static let error = MurielColor(name: .hotRed)
    static let neutral = MurielColor(name: .gray)
    static let primary = MurielColor(name: .blue)
    static let success = MurielColor(name: .green)
    static let text = MurielColor(name: .gray, shade: .shade800)
    static let textSubtle = MurielColor(name: .gray, shade: .shade500)
    static let warning = MurielColor(name: .hotYellow)

    // MARK: - Additional iOS semantic colors
    static let navigationBar = MurielColor(name: .blue)
    static let navigationBarShadow = MurielColor(name: .blue, shade: .shade800)

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)-\(shade)"
    }
}

extension UIColor {
    /// Get a UIColor from the Muriel color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a MurielColorIdentifier
    /// - Returns: UIColor. Red in cases of error
    class func muriel(color murielColor: MurielColor) -> UIColor {
        let assetName = murielColor.assetName()
        guard let color = UIColor(named: assetName) else {
            return .red
        }
        return color
    }

    /// Muriel accent color
    static var accent: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: .accent)
        } else {
            return WPStyleGuide.jazzyOrange()
        }
    }
    static var accentDark: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .accent, shade: .shade700))
        } else {
            return WPStyleGuide.fireOrange()
        }
    }
    class func accent(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .accent, shade: shade))
    }

    /// Muriel divider color
    static var divider = muriel(color: .divider)

    /// Muriel error color
    static var error: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: .error)
        } else {
            return WPStyleGuide.errorRed()
        }
    }
    static var errorDark: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .error, shade: .shade700))
        } else {
            return WPStyleGuide.alertRedDarker()
        }
    }
    class func error(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .error, shade: shade))
    }

    /// Muriel neutral color
    static var neutral = muriel(color: .neutral)
    class func neutral(shade: MurielColorShade) -> UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .neutral, shade: shade))
        } else {
            // here's compatibility with the old colors
            switch shade {
            case .shade700, .shade800, .shade900:
                return WPStyleGuide.darkGrey()
            case .shade600:
                return WPStyleGuide.greyDarken30()
            case .shade500:
                return WPStyleGuide.greyDarken20()
            case .shade400:
                return WPStyleGuide.greyDarken10()
            case .shade300:
                return WPStyleGuide.grey()
            case .shade200:
                return WPStyleGuide.greyLighten10()
            case .shade100:
                return WPStyleGuide.greyLighten20()
            case .shade50:
                return WPStyleGuide.greyLighten30()
            case .shade0:
                return WPStyleGuide.lightGrey()
            }
        }
    }

    /// Muriel primary color
    static var primary: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: .primary)
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }
    static var primaryLight: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .primary, shade: .shade300))
        } else {
            return WPStyleGuide.lightBlue()
        }
    }
    static var primaryDark: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .primary, shade: .shade700))
        } else {
            return WPStyleGuide.darkBlue()
        }
    }
    class func primary(shade: MurielColorShade) -> UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .primary, shade: shade))
        } else {
            // here's compatibility with the old colors
            switch shade {
            case .shade700, .shade800, .shade900:
                return WPStyleGuide.darkBlue()
            case .shade500, .shade600:
                return WPStyleGuide.wordPressBlue()
            case .shade400:
                return WPStyleGuide.mediumBlue()
            case .shade300, .shade200, .shade100, .shade50, .shade0:
                return WPStyleGuide.lightBlue()
            }
        }
    }

    /// Muriel success color
    static var success: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: .success)
        } else {
            return WPStyleGuide.validGreen()
        }
    }
    class func success(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .success, shade: shade))
    }

    /// Muriel text color
    static var text = muriel(color: .text)

    /// Muriel text subtle color
    static var textSubtle = muriel(color: .textSubtle)

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .warning, shade: shade))
    }

    /// Muriel/iOS navigation color
    static var textInverted = UIColor.white

    static var navigationBar = muriel(color: .navigationBar)

    /// Muriel/iOS unselected color
    static var unselected: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .gray, shade: .shade300))
        } else {
            return WPStyleGuide.greyLighten10()
        }
    }

    /// MARK: Muriel colors for buttons
    static var buttonBase: UIColor {
        if FeatureFlag.murielColors.enabled {
            return .accent
        } else {
            return WPStyleGuide.mediumBlue()
        }
    }
    static var buttonBorder: UIColor {
        if FeatureFlag.murielColors.enabled {
            return .accentDark
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }
    static var buttonDown: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .hotPink, shade: .shade800))
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }
    static var buttonDownBorder: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .hotPink, shade: .shade900))
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }
    static var buttonSecondaryBase = UIColor.textInverted
    static var buttonSecondaryBorder = UIColor.neutral(shade: .shade100)
    static var buttonSecondaryDown = UIColor.neutral(shade: .shade100)
    static var buttonSecondaryDownBorder = UIColor.neutral(shade: .shade400)
}
