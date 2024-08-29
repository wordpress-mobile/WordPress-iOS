import Foundation
import WordPressShared

/// - Warning:
/// This configuration struct has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)

    /// Get a UIColor from the Muriel color palette, adjusted to a given shade
    /// - Parameter color: an instance of a MurielColor
    /// - Parameter shade: a MurielColorShade
    static func muriel(color: MurielColor, _ shade: MurielColorShade) -> UIColor {
        MurielColor(from: color, shade: shade).color
    }

    /// Get a UIColor from the Muriel color palette by name, adjusted to a given shade
    /// - Parameters:
    ///   - name: a MurielColorName
    ///   - shade: a MurielColorShade
    /// - Returns: the desired color/shade
    static func muriel(name: MurielColorName, _ shade: MurielColorShade) -> UIColor {
        MurielColor(name: name, shade: shade).color
    }

    static func primary(_ shade: MurielColorShade) -> UIColor {
        MurielColor(name: .blue, shade: shade).color
    }

    static func accent(_ shade: MurielColorShade) -> UIColor {
        MurielColor(name: .pink, shade: shade).color
    }

    static func gray(_ shade: MurielColorShade) -> UIColor {
        MurielColor(name: .gray, shade: shade).color
    }

    static func blue(_ shade: MurielColorShade) -> UIColor {
        MurielColor(name: .blue, shade: shade).color
    }

    static func jetpackGreen(_ shade: MurielColorShade) -> UIColor {
        MurielColor(name: .jetpackGreen, shade: shade).color
    }

    static let primaryLight: UIColor = primary(.shade30)
    static let primaryDark: UIColor = primary(.shade70)

    static func neutral(_ shade: MurielColorShade) -> UIColor {
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

// MARK: - Colors
extension AppStyleGuide {
    static let accent = MurielColor(name: .pink).color
    static let brand = MurielColor(name: .wordPressBlue).color
    static let divider = MurielColor(name: .gray, shade: .shade10).color
    static let error = MurielColor(name: .red).color
    static let gray = MurielColor(name: .gray).color
    static let primary = MurielColor(name: .blue).color
    static let success = MurielColor(name: .green).color
    static let text = MurielColor(name: .gray, shade: .shade80).color
    static let textSubtle = MurielColor(name: .gray, shade: .shade50).color
    static let warning = MurielColor(name: .yellow).color
    static let jetpackGreen = MurielColor(name: .jetpackGreen).color
    static let editorPrimary = MurielColor(name: .blue).color
}

// MARK: - Images
extension AppStyleGuide {
    static let mySiteTabIcon = UIImage(named: "icon-tab-mysites")
}

// MARK: - Fonts
extension AppStyleGuide {
    static func prominentFont(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.serifFontForTextStyle(textStyle, fontWeight: weight)
    }
}
