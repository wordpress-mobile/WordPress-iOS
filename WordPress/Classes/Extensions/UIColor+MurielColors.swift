/// Only necessary until the .murielColors feature flag is removed
import WordPressShared

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

    var description: String {
        return "\(rawValue)"
    }
}

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
    static let accent = MurielColor(name: .pink)
    static let brand = MurielColor(name: .wordPressBlue)
    static let divider = MurielColor(name: .gray, shade: .shade10)
    static let error = MurielColor(name: .red)
    static let neutral = MurielColor(name: .gray)
    static let primary = MurielColor(name: .blue)
    static let success = MurielColor(name: .green)
    static let text = MurielColor(name: .gray, shade: .shade80)
    static let textSubtle = MurielColor(name: .gray, shade: .shade50)
    static let warning = MurielColor(name: .yellow)

    // MARK: - Additional iOS semantic colors
    static let navigationBar = MurielColor(name: .wordPressBlue)
    static let tableBackground = MurielColor(name: .gray, shade: .shade0)

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)\(shade)"
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
            return muriel(color: MurielColor(from: .accent, shade: .shade70))
        } else {
            return WPStyleGuide.fireOrange()
        }
    }

    class func accent(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .accent, shade: shade))
    }

    /// Muriel brand color
    static var brand = muriel(color: .brand)
    class func brand(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .brand, shade: shade))
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
            return muriel(color: MurielColor(from: .error, shade: .shade70))
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
            case .shade70, .shade80, .shade90:
                return WPStyleGuide.darkGrey()
            case .shade60:
                return WPStyleGuide.greyDarken30()
            case .shade50:
                return WPStyleGuide.greyDarken20()
            case .shade40:
                return WPStyleGuide.greyDarken10()
            case .shade30:
                return WPStyleGuide.grey()
            case .shade20:
                return WPStyleGuide.greyLighten10()
            case .shade10:
                return WPStyleGuide.greyLighten20()
            case .shade5:
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
            return muriel(color: MurielColor(from: .primary, shade: .shade30))
        } else {
            return WPStyleGuide.lightBlue()
        }
    }

    static var primaryDark: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .primary, shade: .shade70))
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
            case .shade70, .shade80, .shade90:
                return WPStyleGuide.darkBlue()
            case .shade50, .shade60:
                return WPStyleGuide.wordPressBlue()
            case .shade40:
                return WPStyleGuide.mediumBlue()
            case .shade30, .shade20, .shade10, .shade5, .shade0:
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

    /// Muriel placeholder text color
    static var textPlaceholder = neutral(shade: .shade30)

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .warning, shade: shade))
    }

    /// Muriel/iOS navigation color
    static var textInverted = UIColor.white

    static var navigationBar = muriel(color: .navigationBar)

    static var tableBackground = muriel(color: .tableBackground)

    /// Muriel/iOS unselected color
    static var unselected: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .gray, shade: .shade20))
        } else {
            return WPStyleGuide.greyLighten10()
        }
    }

    /// MARK: Muriel colors for buttons
    static var primaryButtonBackground: UIColor {
        if FeatureFlag.murielColors.enabled {
            return .accent
        } else {
            return WPStyleGuide.mediumBlue()
        }
    }

    static var primaryButtonBorder: UIColor {
        if FeatureFlag.murielColors.enabled {
            return .accentDark
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }

    static var primaryButtonDownBackground: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .pink, shade: .shade80))
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }

    static var primaryButtonDownBorder: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(name: .pink, shade: .shade90))
        } else {
            return WPStyleGuide.wordPressBlue()
        }
    }
}
