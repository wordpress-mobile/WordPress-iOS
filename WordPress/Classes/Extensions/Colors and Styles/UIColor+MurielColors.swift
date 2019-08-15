/// Only necessary until the .murielColors feature flag is removed
import WordPressShared

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
}
// MARK: - Basic Colors
extension UIColor {
    /// Muriel accent color
    static var accent: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: .accent)
        } else {
            return WPStyleGuide.jazzyOrange()
        }
    }

    class func accent(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .accent, shade: shade))
    }

    static var accentDark: UIColor {
        if FeatureFlag.murielColors.enabled {
            return muriel(color: MurielColor(from: .accent, shade: .shade70))
        } else {
            return WPStyleGuide.fireOrange()
        }
    }

    /// Muriel brand color
    static var brand = muriel(color: .brand)
    class func brand(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .brand, shade: shade))
    }

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

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .warning, shade: shade))
    }
}

// MARK: - UI elements
extension UIColor {

    /// Default text color: high contrast
    static var text: UIColor {
        let fallbackColor = muriel(color: .text)
        #if XCODE11
        if #available(iOS 13, *) {
            return .label
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    /// Secondary text color: less contrast
    static var textSubtle: UIColor {
        let fallbackColor = muriel(color: .neutral)
        #if XCODE11
        if #available(iOS 13, *) {
            return .secondaryLabel
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    /// Very low contrast text
    static var textTertiary: UIColor {
        let fallbackColor = UIColor.neutral(shade: .shade10)
        #if XCODE11
        if #available(iOS 13, *) {
            return .tertiaryLabel
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    /// Very, very low contrast text
    static var textQuaternary: UIColor {
        let fallbackColor = UIColor.neutral(shade: .shade10)
        #if XCODE11
        if #available(iOS 13, *) {
            return .quaternaryLabel
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    static var textInverted = UIColor(light: .white, dark: .neutral(shade: .shade0))
    static var textPlaceholder = neutral(shade: .shade30)

    /// Muriel/iOS navigation color
    static var navigationBar = UIColor(light: .brand, dark: .neutral(shade: .shade0))

    // MARK: - Table Views
    
    static var divider: UIColor {
        #if XCODE11
        if #available(iOS 13, *) {
            return .separator
        } else {
            return muriel(color: .divider)
        }
        #else
        return muriel(color: .divider)
        #endif
    }

    /// WP color for table foregrounds (cells, etc)
    static var tableForeground: UIColor {
        #if XCODE11
        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        } else {
            return .white
        }
        #else
        return .white
        #endif
    }

    static var tableForegroundUnread: UIColor {
        #if XCODE11
        if #available(iOS 13, *) {
            return .tertiarySystemGroupedBackground
        } else {
            return .primary(shade: .shade0)
        }
        #else
        return .primary(shade: .shade0)
        #endif
    }

    static var tableBackground: UIColor {
        let fallbackColor = muriel(color: .tableBackground)
        #if XCODE11
        if #available(iOS 13, *) {
            return .systemGroupedBackground
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    /// For icons that are present in a table view, or similar list
    static var listIcon: UIColor {
        let fallbackColor = UIColor(light: .neutral(shade: .shade20), dark: .neutral(shade: .shade50))
        #if XCODE11
        if #available(iOS 13, *) {
            return .secondaryLabel
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    /// For small icons, such as the badges on notification gravatars
    static var listSmallIcon: UIColor {
        let fallbackColor = UIColor.neutral(shade: .shade20)
        #if XCODE11
        if #available(iOS 13, *) {
            return .systemGray
        } else {
            return fallbackColor
        }
        #else
        return fallbackColor
        #endif
    }

    static var filterBarSelected: UIColor {
        let lightModeColor = UIColor.primary
        #if XCODE11
        if #available(iOS 13, *) {
            return UIColor(light: lightModeColor, dark: .label)
        } else {
            return lightModeColor
        }
        #else
        return lightModeColor
        #endif
    }

    /// Tab bar unselected color
    static var tabUnselected: UIColor =  UIColor(light: .neutral(shade: .shade20), dark: .neutral(shade: .shade50))

// MARK: - WP Fancy Buttons
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

extension UIColor {
    // A way to create dynamic colors that's compatible with iOS 11 & 12
    convenience init(light: UIColor, dark: UIColor) {
        #if XCODE11
        if #available(iOS 13, *) {
            self.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            self.init(color: light)
        }
        #else
            // in older versions of iOS, we assume light mode
            self.init(color: light)
        #endif
    }

    convenience init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
