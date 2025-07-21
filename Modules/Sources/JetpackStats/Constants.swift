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

        static let statsBackground = Color(UIColor(
            light: CSColor.Gray.shade(.shade0),
            dark: UIColor.systemBackground
        ))

        static let blue = Color(palette: CSColor.Blue.self)
        static let purple = Color(palette: CSColor.Purple.self)
        static let red = Color(palette: CSColor.Red.self)
        static let green = Color(palette: CSColor.Green.self)
        static let orange = Color(palette: CSColor.Orange.self)
        static let pink = Color(palette: CSColor.Pink.self)
        static let celadon = Color(palette: CSColor.Celadon.self)
    }

    static let step1: CGFloat = 12
    static let step2: CGFloat = 18
    static let step3: CGFloat = 24
}

private extension Color {
    init<T: ColorStudio.ColorStudioPalette>(palette: T.Type) {
        self.init(uiColor: UIColor(light: T.shade(.shade50), dark: T.shade(.shade40)))
    }
}
