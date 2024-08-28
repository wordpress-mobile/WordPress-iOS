@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {
    /// Get a UIColor from the Muriel color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a MurielColor
    /// - Returns: UIColor. Red in cases of error
    class func muriel(color murielColor: MurielColor) -> UIColor {
        let color = UIColor(named: murielColor.assetName)

        guard let unwrappedColor = color else {
            return .red
        }

        return unwrappedColor
    }
    /// Get a UIColor from the Muriel color palette, adjusted to a given shade
    /// - Parameter color: an instance of a MurielColor
    /// - Parameter shade: a MurielColorShade
    class func muriel(color: MurielColor, _ shade: MurielColorShade) -> UIColor {
        let newColor = MurielColor(from: color, shade: shade)
        return muriel(color: newColor)
    }

    /// Get a UIColor from the Muriel color palette by name, adjusted to a given shade
    /// - Parameters:
    ///   - name: a MurielColorName
    ///   - shade: a MurielColorShade
    /// - Returns: the desired color/shade
    class func muriel(name: MurielColorName, _ shade: MurielColorShade) -> UIColor {
        let newColor = MurielColor(name: name, shade: shade)
        return muriel(color: newColor)
    }
}
// MARK: - Basic Colors
@available(*, deprecated, message: "Use AppStyleGuide instead")
extension UIColor {
    /// Muriel accent color
    static var accent = AppStyleGuide.accent
    static var accentDark: UIColor {
        fatalError()
    }

    /// Muriel brand color
    static var brand = AppStyleGuide.brand

    /// Muriel error color
    static var error = AppStyleGuide.error

    /// Muriel primary color
    static var primary = AppStyleGuide.primary

    /// Muriel editor primary color
    static var editorPrimary = AppStyleGuide.editorPrimary

    /// Muriel success color
    static var success = AppStyleGuide.success

    /// Muriel warning color
    static var warning = AppStyleGuide.warning

    /// Muriel jetpack green color
    static var jetpackGreen = AppStyleGuide.jetpackGreen
}

// MARK: - Grays
extension UIColor {
    /// Muriel gray palette
    /// - Parameter shade: a MurielColorShade of the desired shade of gray
    class func gray(_ shade: MurielColorShade) -> UIColor {
        AppStyleGuide.muriel(name: .gray, shade)
    }

    /// Muriel neutral colors, which invert in dark mode
    /// - Parameter shade: a MurielColorShade of the desired neutral shade
    static var neutral: UIColor {
        return neutral(.shade50)
    }
    class func neutral(_ shade: MurielColorShade) -> UIColor {
        return switch shade {
            case .shade0: UIColor(light: gray(.shade0), dark: gray(.shade100))
            case .shade5: UIColor(light: gray(.shade5), dark: gray(.shade90))
            case .shade10: UIColor(light: gray(.shade10), dark: gray(.shade80))
            case .shade20: UIColor(light: gray(.shade20), dark: gray(.shade70))
            case .shade30: UIColor(light: gray(.shade30), dark: gray(.shade60))
            case .shade40: UIColor(light: gray(.shade40), dark: gray(.shade50))
            case .shade50: UIColor(light: gray(.shade50), dark: gray(.shade40))
            case .shade60: UIColor(light: gray(.shade60), dark: gray(.shade30))
            case .shade70: UIColor(light: gray(.shade70), dark: gray(.shade20))
            case .shade80: UIColor(light: gray(.shade80), dark: gray(.shade10))
            case .shade90: UIColor(light: gray(.shade90), dark: gray(.shade5))
            case .shade100: UIColor(light: gray(.shade100), dark: gray(.shade0))
        }
    }
}

// MARK: - UI elements
extension UIColor {
    /// The most basic background: white in light mode, black in dark mode
    @available(*, deprecated, renamed: "systemBackground", message: "Use the platform's default instead")
    static var basicBackground: UIColor {
        return .systemBackground
    }

    /// Default text color: high contrast
    @available(*, deprecated, renamed: "label", message: "Use the platform's default instead")
    static var text: UIColor {
        return .label
    }

    /// Secondary text color: less contrast
    @available(*, deprecated, renamed: "secondaryLabel", message: "Use the platform's default instead")
    static var textSubtle: UIColor {
        return .secondaryLabel
    }

    /// Very low contrast text
    @available(*, deprecated, renamed: "tertiaryLabel", message: "Use the platform's default instead")
    static var textTertiary: UIColor {
        return .tertiaryLabel
    }

    /// Very, very low contrast text
    @available(*, deprecated, renamed: "quaternaryLabel", message: "Use the platform's default instead")
    static var textQuaternary: UIColor {
        return .quaternaryLabel
    }

    static var textInverted = UIColor(light: .white, dark: .gray(.shade100))

    @available(*, deprecated, renamed: "tertiaryLabel", message: "Use the platform's default instead")
    static var textPlaceholder: UIColor {
        return .tertiaryLabel
    }
    static var placeholderElement: UIColor {
        return UIColor(light: .systemGray5, dark: .systemGray4)
    }

    static var placeholderElementFaded: UIColor {
        return UIColor(light: .systemGray6, dark: .systemGray5)
    }

    // MARK: - Table Views
    @available(*, deprecated, renamed: "separator", message: "Use the platform's default instead")
    static var divider: UIColor {
        return .separator
    }

    /// WP color for table foregrounds (cells, etc)
    @available(*, deprecated, renamed: "secondarySystemGroupedBackground", message: "Use the platform's default instead")
    static var listForeground: UIColor {
        return .secondarySystemGroupedBackground
    }

    @available(*, deprecated, renamed: "listBackground", message: "Use the platform's default instead")
    static var listBackground: UIColor {
        return .systemGroupedBackground
    }

    /// For icons that are present in a table view, or similar list
    @available(*, deprecated, renamed: "listIcon", message: "Use the platform's default instead")
    static var listIcon: UIColor {
        return .secondaryLabel
    }

    /// For small icons, such as the badges on notification gravatars
    @available(*, deprecated, renamed: "listSmallIcon", message: "Use the platform's default instead")
    static var listSmallIcon: UIColor {
        return .systemGray
    }

    // MARK: - Others

    static var prologueBackground: UIColor {
        UIColor(
            light: AppStyleGuide.muriel(name: .blue, .shade0),
            dark: .systemBackground
        )
    }
}

@objc
extension UIColor {
    // A way to create dynamic colors that's compatible with iOS 11 & 12
    @objc
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
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

extension UIColor {
    func color(for trait: UITraitCollection?) -> UIColor {
        if let trait = trait {
            return resolvedColor(with: trait)
        }
        return self
    }

    func lightVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .light))
    }

    func darkVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .dark))
    }
}
