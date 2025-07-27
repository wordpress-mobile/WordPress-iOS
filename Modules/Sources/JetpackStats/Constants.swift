import SwiftUI
import ColorStudio

enum Constants {
    enum Colors {
        static let positiveChangeForeground = Color(UIColor(
            light: UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0),
            dark: UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        ))

        static let negativeChangeForeground = Color(UIColor(
            light: UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0),
            dark: UIColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 1.0)
        ))

        static let positiveChangeBackground = Color(UIColor(
            light: UIColor(red: 0.9, green: 0.95, blue: 0.9, alpha: 1.0),
            dark: UIColor(red: 0.15, green: 0.3, blue: 0.15, alpha: 1.0)
        ))

        static let negativeChangeBackground = Color(UIColor(
            light: UIColor(red: 0.95, green: 0.9, blue: 0.9, alpha: 1.0),
            dark: UIColor(red: 0.3, green: 0.15, blue: 0.15, alpha: 1.0)
        ))

        static let background = Color(UIColor(
            light: UIColor.secondarySystemBackground,
            dark: UIColor.systemBackground
        ))

        static let secondaryBackground = Color(UIColor(
            light: UIColor.systemBackground,
            dark: UIColor.secondarySystemBackground
        ))

        static let blue = Color(palette: CSColor.Blue.self)
        static let purple = Color(palette: CSColor.Purple.self)
        static let red = Color(palette: CSColor.Red.self)
        static let green = Color(palette: CSColor.Green.self)
        static let orange = Color(palette: CSColor.Orange.self)
        static let pink = Color(palette: CSColor.Pink.self)
        static let celadon = Color(palette: CSColor.Celadon.self)

        static let uiColorBlue = UIColor(palette: CSColor.Blue.self)

        static let jetpack = Color(palette: CSColor.JetpackGreen.self)
    }

    static let step0_5: CGFloat = 9
    static let step1: CGFloat = 12
    static let step2: CGFloat = 18
    static let step3: CGFloat = 24
    static let step4: CGFloat = 32

    static func heatmapColor(baseColor: Color, intensity: Double) -> Color {
        if intensity == 0 {
            return Color(UIColor(
                light: UIColor.secondarySystemBackground,
                dark: UIColor.tertiarySystemBackground
            ))
        }

        // Use graduated opacity based on intensity
        if intensity <= 0.25 {
            return baseColor.opacity(0.07)
        } else if intensity <= 0.5 {
            return baseColor.opacity(0.14)
        } else if intensity <= 0.75 {
            return baseColor.opacity(0.25)
        } else {
            return baseColor.opacity(0.38)
        }
    }
}

private extension Color {
    init<T: ColorStudio.ColorStudioPalette>(palette: T.Type) {
        self.init(uiColor: UIColor(palette: palette))
    }
}

private extension UIColor {
    convenience init<T: ColorStudio.ColorStudioPalette>(palette: T.Type) {
        self.init(light: T.shade(.shade50), dark: T.shade(.shade40))
    }
}
