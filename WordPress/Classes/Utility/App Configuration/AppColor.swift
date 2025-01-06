import Foundation
import ColorStudio
import SwiftUI

struct UIAppColor {
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

    static func pink(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Pink.shade(shade)
    }

    static func yellow(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Yellow.shade(shade)
    }

    static func purple(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Purple.shade(shade)
    }

    static func orange(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Orange.shade(shade)
    }

    static func celadon(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Celadon.shade(shade)
    }

    static func wordPressBlue(_ shade: ColorStudioShade) -> UIColor {
        CSColor.WordPressBlue.shade(shade)
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

    static let accent = CSColor.Pink.base

#if IS_JETPACK
    static let tint = UIColor.label

    static let primary = UIColor(light: CSColor.JetpackGreen.shade(.shade40), dark: CSColor.JetpackGreen.shade(.shade30))

    static func primary(_ shade: ColorStudioShade) -> UIColor {
        CSColor.JetpackGreen.shade(shade)
    }
#endif

#if IS_WORDPRESS
    static let tint = primary

    static let primary = UIColor(light: CSColor.Blue.base, dark: primary(.shade40))

    static func primary(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Blue.shade(shade)
    }
#endif

    static let divider = CSColor.Gray.shade(.shade10)
    static let error = CSColor.Red.base
    static let gray = CSColor.Gray.base
    static let blue = CSColor.Blue.base

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

    static let placeholderElement = UIColor(light: .systemGray5, dark: .systemGray4)
    static let placeholderElementFaded: UIColor = UIColor(light: .systemGray6, dark: .systemGray5)

    static let prologueBackground = UIColor(light: blue(.shade0), dark: .systemBackground)

    static let switchStyle: SwitchToggleStyle = SwitchToggleStyle(tint: Color(UIAppColor.primary))
}

struct AppColor {
    static let tint = Color(UIAppColor.tint)
    static let primary = Color(UIAppColor.primary)
}
