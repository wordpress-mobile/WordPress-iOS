import UIKit
import SwiftUI
import ColorStudio
import BuildSettingsKit

public enum UIAppColor {
    /// A tint color used in places like navigation bars.
    ///
    /// - note: The Jetpack app uses
    public static var tint: UIColor {
        switch AppBrand.current {
        case .wordpress: primary
        case .jetpack: UIColor.label
        }
    }

    public static var primary: UIColor {
        switch AppBrand.current {
        case .wordpress: UIColor(light: CSColor.Blue.base, dark: primary(.shade40))
        case .jetpack: UIColor(light: CSColor.JetpackGreen.shade(.shade40), dark: CSColor.JetpackGreen.shade(.shade30))
        }
    }

    public static func primary(_ shade: ColorStudioShade) -> UIColor {
        switch AppBrand.current {
        case .wordpress: CSColor.Blue.shade(shade)
        case .jetpack: CSColor.JetpackGreen.shade(shade)
        }
    }
}

extension UIAppColor {
    public static func accent(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Pink.shade(shade)
    }

    public static func error(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Red.shade(shade)
    }

    public static func warning(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Yellow.shade(shade)
    }

    public static func success(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Green.shade(shade)
    }

    public static func gray(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Gray.shade(shade)
    }

    public static func blue(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Blue.shade(shade)
    }

    public static func green(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Green.shade(shade)
    }

    public static func red(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Red.shade(shade)
    }

    public static func pink(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Pink.shade(shade)
    }

    public static func yellow(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Yellow.shade(shade)
    }

    public static func purple(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Purple.shade(shade)
    }

    public static func orange(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Orange.shade(shade)
    }

    public static func celadon(_ shade: ColorStudioShade) -> UIColor {
        CSColor.Celadon.shade(shade)
    }

    public static func wordPressBlue(_ shade: ColorStudioShade) -> UIColor {
        CSColor.WordPressBlue.shade(shade)
    }

    public static func jetpackGreen(_ shade: ColorStudioShade) -> UIColor {
        CSColor.JetpackGreen.shade(shade)
    }

    public static let primaryLight: UIColor = primary(.shade30)
    public static let primaryDark: UIColor = primary(.shade70)

    public static func neutral(_ shade: ColorStudioShade) -> UIColor {
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

    public static let accent = CSColor.Pink.base
    public static let divider = CSColor.Gray.shade(.shade10)
    public static let error = CSColor.Red.base
    public static let gray = CSColor.Gray.base
    public static let blue = CSColor.Blue.base

    public static let success = CSColor.Green.base
    public static let text = CSColor.Gray.shade(.shade80)
    public static let textSubtle = CSColor.Gray.shade(.shade50)
    public static let warning = CSColor.Yellow.base
    public static let jetpackGreen = CSColor.JetpackGreen.base
    public static let editorPrimary = CSColor.Blue.base
    public static let neutral = CSColor.Gray.base

    public static let statsPrimaryHighlight = UIColor(light: accent(.shade30), dark: accent(.shade60))
    public static let statsSecondaryHighlight = UIColor(light: accent(.shade60), dark: accent(.shade30))

    // TODO : These should be customized for WP and JP
    public static let appBarTint = UIColor.systemOrange
    public static let appBarText = UIColor.systemOrange

    public static let placeholderElement = UIColor(light: .systemGray5, dark: .systemGray4)
    public static let placeholderElementFaded: UIColor = UIColor(light: .systemGray6, dark: .systemGray5)

    public static let prologueBackground = UIColor(light: blue(.shade0), dark: .systemBackground)

    public static let switchStyle: SwitchToggleStyle = SwitchToggleStyle(tint: Color(UIAppColor.primary))
}

public enum AppColor {
    public static var tint: Color { Color(UIAppColor.tint) }
    public static var primary: Color { Color(UIAppColor.primary) }
}

private extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
    }
}
