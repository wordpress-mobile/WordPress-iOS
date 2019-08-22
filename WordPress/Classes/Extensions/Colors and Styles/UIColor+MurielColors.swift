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
}
// MARK: - Basic Colors
extension UIColor {
    /// Muriel accent color
    static var accent = muriel(color: .accent)
    static var accentDark = muriel(color: MurielColor(from: .accent, shade: .shade70))
    class func accent(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .accent, shade: shade))
    }

    /// Muriel brand color
    static var brand = muriel(color: .brand)
    class func brand(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .brand, shade: shade))
    }

    /// Muriel error color
    static var error = muriel(color: .error)
    static var errorDark = muriel(color: MurielColor(from: .error, shade: .shade70))
    class func error(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .error, shade: shade))
    }

    /// Muriel primary color
    static var primary = muriel(color: .primary)
    static var primaryLight = muriel(color: MurielColor(from: .primary, shade: .shade30))
    static var primaryDark = muriel(color: MurielColor(from: .primary, shade: .shade70))
    class func primary(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .primary, shade: shade))
    }

    /// Muriel success color
    static var success = muriel(color: .success)
    class func success(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .success, shade: shade))
    }

    /// Muriel warning color
    static var warning = muriel(color: .warning)
    class func warning(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .warning, shade: shade))
    }
}

// MARK: - Grays
extension UIColor {
    /// Muriel gray palette
    /// - Parameter shade: a MurielColorShade of the desired shade of gray
    class func gray(_ shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .gray, shade: shade))
    }

    /// Muriel neutral colors, which invert in dark mode
    /// - Parameter shade: a MurielColorShade of the desired neutral shade
    static var neutral: UIColor {
        return neutral(.shade50)
    }
    class func neutral(_ shade: MurielColorShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade0)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade90)))
            case .shade5:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade5)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade80)))
            case .shade10:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade10)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade70)))
            case .shade20:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade20)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade60)))
            case .shade30:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade30)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade50)))
            case .shade40:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade40)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade40)))
            case .shade50:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade50)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade30)))
            case .shade60:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade60)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade20)))
            case .shade70:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade70)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade10)))
            case .shade80:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade80)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade5)))
            case .shade90:
            return UIColor(light: muriel(color: MurielColor(name: .gray, shade: .shade90)),
                           dark: muriel(color: MurielColor(name: .gray, shade: .shade0)))
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
        return UIColor.neutral(.shade10)
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

    static var textInverted = UIColor(light: .white, dark: .neutral(.shade0))
    static var textPlaceholder = neutral(.shade30)

    /// Muriel/iOS navigation color
    static var navigationBar = UIColor(light: .brand, dark: .neutral(.shade0))

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
    static var tableForeground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .secondarySystemGroupedBackground
            }
        #endif
        return .white
    }

    static var tableForegroundUnread: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .tertiarySystemGroupedBackground
            }
        #endif
        return .primary(.shade0)
    }

    static var tableBackground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemGroupedBackground
            }
        #endif
        return muriel(color: .tableBackground)
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
                return UIColor(light: white, dark: .neutral(.shade0))
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

    /// Tab bar unselected color
    static var tabUnselected: UIColor =  UIColor(light: .neutral(.shade20), dark: .neutral(.shade50))

// MARK: - WP Fancy Buttons
    static var primaryButtonBackground = accent
    static var primaryButtonBorder = accentDark
    static var primaryButtonDownBackground = muriel(color: MurielColor(name: .pink, shade: .shade80))
    static var primaryButtonDownBorder = muriel(color: MurielColor(name: .pink, shade: .shade90))
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
