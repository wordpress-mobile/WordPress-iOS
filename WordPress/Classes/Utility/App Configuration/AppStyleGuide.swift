import Foundation
import WordPressShared

/// - Warning:
/// This configuration struct has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)

    static func primary(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Blue.shade(shade)
    }

    static func accent(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Pink.shade(shade)
    }

    static func error(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Red.shade(shade)
    }

    static func warning(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Yellow.shade(shade)
    }

    static func success(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Green.shade(shade)
    }

    static func gray(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Gray.shade(shade)
    }

    static func blue(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Blue.shade(shade)
    }

    static func green(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Green.shade(shade)
    }

    static func red(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Red.shade(shade)
    }

    static func jetpackGreen(_ shade: ColorStudioShade) -> UIColor {
        CSColor.JetpackGreen.shade(shade)
    }

    static let primaryLight: UIColor = primary(.shade30)
    static let primaryDark: UIColor = primary(.shade70)

    static func neutral(_ shade: ColorStudioShade) -> UIColor {
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
    static let accent = CSColor.Pink.base
    static let brand = CSColor.WordPressBlue.base
    static let divider = CSColor.Gray.shade(.shade10)
    static let error = CSColor.Red.base
    static let gray = CSColor.Gray.base
    static let blue = CSColor.Blue.base
    static let primary = CSColor.Blue.base
    static let success = CSColor.Green.base
    static let text = CSColor.Gray.shade(.shade80)
    static let textSubtle = CSColor.Gray.shade(.shade50)
    static let warning = CSColor.Yellow.base
    static let jetpackGreen = CSColor.JetpackGreen.base
    static let editorPrimary = CSColor.Blue.base
    static let neutral = CSColor.Gray.base

    static let statsPrimaryHighlight = UIColor(light: accent(.shade30), dark: accent(.shade60))
    static let statsSecondaryHighlight = UIColor(light: accent(.shade60), dark: accent(.shade30))

    // TODO : These should be customized for WP and JP
    static let appBarTint = UIColor.systemOrange
    static let appBarText = UIColor.systemOrange
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
