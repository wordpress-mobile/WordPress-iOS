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
    static var accent = muriel(color: .accent)
    static var accentDark = muriel(color: MurielColor(from: .accent, shade: .shade70))
    class func accent(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .accent, shade: shade))
    }

    /// Muriel brand color
    static var brand = muriel(color: .brand)
    class func brand(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .brand, shade: shade))
    }

    /// Muriel error color
    static var error = muriel(color: .error)
    static var errorDark = muriel(color: MurielColor(from: .error, shade: .shade70))
    class func error(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .error, shade: shade))
    }

    /// Muriel neutral color
    static var neutral = muriel(color: .neutral)
    class func neutral(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .neutral, shade: shade))
    }

    /// Muriel primary color
    static var primary = muriel(color: .primary)
    static var primaryLight = muriel(color: MurielColor(from: .primary, shade: .shade30))
    static var primaryDark = muriel(color: MurielColor(from: .primary, shade: .shade70))
    class func primary(shade: MurielColorShade) -> UIColor {
        return muriel(color: MurielColor(from: .primary, shade: shade))
    }

    /// Muriel success color
    static var success = muriel(color: .success)
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
        return muriel(color: .neutral)
    }

    /// Very low contrast text
    static var textTertiary: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .tertiaryLabel
            }
        #endif
        return UIColor.neutral(shade: .shade10)
    }

    /// Very, very low contrast text
    static var textQuaternary: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .quaternaryLabel
            }
        #endif
        return UIColor.neutral(shade: .shade10)
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
        return .primary(shade: .shade0)
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
        return .neutral(shade: .shade20)
    }

    /// For small icons, such as the badges on notification gravatars
    static var listSmallIcon: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return .systemGray
            }
        #endif
        return UIColor.neutral(shade: .shade20)
    }

    static var filterBarBackground: UIColor {
        #if XCODE11
            if #available(iOS 13, *) {
                return UIColor(light: white, dark: .neutral(shade: .shade0))
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
        return .neutral(shade: .shade30)
    }

    /// Tab bar unselected color
    static var tabUnselected: UIColor =  UIColor(light: .neutral(shade: .shade20), dark: .neutral(shade: .shade50))

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
