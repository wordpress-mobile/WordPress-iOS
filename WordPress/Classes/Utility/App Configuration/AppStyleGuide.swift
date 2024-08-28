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
