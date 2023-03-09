import SwiftUI

enum AppColor {

    static private(set) var color: Color = savedColor ?? defaultColor {
        didSet {
            savedColor = color
        }
    }

    static var uiColor: UIColor {
        .init(color)
    }

    static var defaultColor: Color {
        if AppConfiguration.isWordPress {
            return Color(UIColor.muriel(color: .init(name: .wordPressBlue)))
        } else if AppConfiguration.isJetpack {
            return Color(UIColor.muriel(color: .init(name: .jetpackGreen)))
        } else {
            assertionFailure("unsupported configuration")
            return .red
        }
    }

    static func update(with newColor: Color) {
        color = newColor
    }

    private static var savedColor: Color? {
        get {
            guard
                let components = defaults.array(forKey: defaultsKey) as? [CGFloat], !components.isEmpty,
                let cgColorSpace: CGColorSpace = .init(name: CGColorSpace.sRGB),
                let cgColor = CGColor(colorSpace: cgColorSpace, components: components)
            else {
                return nil
            }
            return Color(cgColor)
        }
        set {
            let components = newValue?.cgColor?.components ?? []
            defaults.set(components, forKey: defaultsKey)
        }
    }

    private static var defaults: UserDefaults {
        .init(suiteName: WPAppGroupName) ?? .standard
    }

    private static let defaultsKey = "AppColorComponents"

}
