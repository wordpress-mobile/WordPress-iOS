extension UIColor {
    /// Get a UIColor from the Muriel color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a MurielColor
    /// - Returns: UIColor. Red in cases of error
    class func muriel(color murielColor: MurielColor) -> UIColor {
        let assetName = murielColor.assetName()
        guard let color = UIColor(named: assetName) else {
            return .red
        }
        return color
    }
    /// Get a UIColor from the Muriel color palette, adjusted to a given shade
    /// - Parameter color: an instance of a MurielColor
    /// - Parameter shade: a MurielColorShade
    class func muriel(color: MurielColor, _ shade: MurielColorShade) -> UIColor {
        let newColor = MurielColor(from: color, shade: shade)
        return muriel(color: newColor)
    }
}
// MARK: - Basic Colors
extension UIColor {
    /// Muriel accent color
    static var accent = muriel(color: .accent)
    static var accentDark = muriel(color: .accent, .shade70)
    class func accent(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .accent, shade)
    }

    /// Muriel brand color
    static var brand = muriel(color: .brand)
    class func brand(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .brand, shade)
    }

    /// Muriel error color
    static var error = muriel(color: .error)
    static var errorDark = muriel(color: .error, .shade70)
    class func error(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .error, shade)
    }

    /// Muriel primary color
    static var primary = muriel(color: .primary)
    static var primaryLight = muriel(color: .primary, .shade30)
    static var primaryDark = muriel(color: .primary, .shade70)
    class func primary(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .primary, shade)
    }

    /// Muriel success color
    static var success = muriel(color: .success)
    class func success(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .success, shade)
    }

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .warning, shade)
    }
}

// MARK: - Grays
extension UIColor {
    /// Muriel gray palette
    /// - Parameter shade: a MurielColorShade of the desired shade of gray
    class func gray(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: .gray, shade)
    }

    /// Muriel neutral colors, which invert in dark mode
    /// - Parameter shade: a MurielColorShade of the desired neutral shade
    static var neutral: UIColor {
        return neutral(.shade50)
    }
    class func neutral(_ shade: MurielColorShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: muriel(color: .gray, .shade0), dark: muriel(color: .gray, .shade100))
            case .shade5:
            return UIColor(light: muriel(color: .gray, .shade5), dark: muriel(color: .gray, .shade90))
            case .shade10:
            return UIColor(light: muriel(color: .gray, .shade10), dark: muriel(color: .gray, .shade80))
            case .shade20:
            return UIColor(light: muriel(color: .gray, .shade20), dark: muriel(color: .gray, .shade70))
            case .shade30:
            return UIColor(light: muriel(color: .gray, .shade30), dark: muriel(color: .gray, .shade60))
            case .shade40:
            return UIColor(light: muriel(color: .gray, .shade40), dark: muriel(color: .gray, .shade50))
            case .shade50:
            return UIColor(light: muriel(color: .gray, .shade50), dark: muriel(color: .gray, .shade40))
            case .shade60:
            return UIColor(light: muriel(color: .gray, .shade60), dark: muriel(color: .gray, .shade30))
            case .shade70:
            return UIColor(light: muriel(color: .gray, .shade70), dark: muriel(color: .gray, .shade20))
            case .shade80:
            return UIColor(light: muriel(color: .gray, .shade80), dark: muriel(color: .gray, .shade10))
            case .shade90:
            return UIColor(light: muriel(color: .gray, .shade90), dark: muriel(color: .gray, .shade5))
            case .shade100:
            return UIColor(light: muriel(color: .gray, .shade100), dark: muriel(color: .gray, .shade0))
        }
    }
}

// MARK: - UI elements
extension UIColor {
    /// The most basic background: white in light mode, black in dark mode
    static var basicBackground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemBackground
            }
        #endif
        return .white
    }

    /// Default text color: high contrast
    static var text: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .label
            }
        #endif
        return muriel(color: .text)
    }

    /// Secondary text color: less contrast
    static var textSubtle: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .secondaryLabel
            }
        #endif
        return muriel(color: .gray)
    }

    /// Very low contrast text
    static var textTertiary: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .tertiaryLabel
            }
        #endif
        return UIColor.neutral(.shade20)
    }

    /// Very, very low contrast text
    static var textQuaternary: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .quaternaryLabel
            }
        #endif
        return UIColor.neutral(.shade10)
    }

    static var textInverted = UIColor(light: .white, dark: .gray(.shade100))
    static var textPlaceholder = neutral(.shade30)

    /// Muriel/iOS navigation color
    static var appBar = UIColor(light: .brand, dark: .gray(.shade100))

    // MARK: - Table Views

    static var divider: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .separator
            }
        #endif
        return muriel(color: .divider)
    }

    /// WP color for table foregrounds (cells, etc)
    static var listForeground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .secondarySystemGroupedBackground
            }
        #endif
        return .white
    }

    static var listForegroundUnread: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .tertiarySystemGroupedBackground
            }
        #endif
        return .primary(.shade0)
    }

    static var listBackground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemGroupedBackground
            }
        #endif
        return muriel(color: .gray, .shade0)
    }

    /// For icons that are present in a table view, or similar list
    static var listIcon: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .secondaryLabel
            }
        #endif
        return .neutral(.shade20)
    }

    /// For small icons, such as the badges on notification gravatars
    static var listSmallIcon: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemGray
            }
        #endif
        return UIColor.neutral(.shade20)
    }

    static var filterBarBackground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return UIColor(light: white, dark: .gray(.shade100))
            }
        #endif
        return white
    }

    static var filterBarSelected: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return UIColor(light: .primary, dark: .label)
            }
        #endif
        return .primary
    }

    /// For icons that are present in a toolbar or similar view
    static var toolbarInactive: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .secondaryLabel
            }
        #endif
        return .neutral(.shade30)
    }

    /// Note: these values are intended to match the iOS defaults
    static var tabUnselected: UIColor =  UIColor(light: UIColor(hexString: "999999"), dark: UIColor(hexString: "757575"))

// MARK: - WP Fancy Buttons
    static var primaryButtonBackground = accent
    static var primaryButtonBorder = accentDark
    static var primaryButtonDownBackground = muriel(color: .accent, .shade80)
    static var primaryButtonDownBorder = muriel(color: .accent, .shade90)

    static var secondaryButtonBackground: UIColor {
        #if XCODE11
        if #available(iOS 13, *) {
            return UIColor(light: .white, dark: .systemGray5)
        }
        #endif
        return .white
    }

    static var secondaryButtonBorder: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemGray3
            }
        #endif
        return .neutral(.shade20)
    }

    static var secondaryButtonDownBackground: UIColor {
        #if XCODE11
        if #available(iOS 13, *) {
            return .systemGray3
        }
        #endif
        return .neutral(.shade20)
    }

    static var secondaryButtonDownBorder: UIColor {
        return secondaryButtonBorder
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
                // in older versions of iOS, we assume light mode
                self.init(color: light)
            }
        #else
            // ditto
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
