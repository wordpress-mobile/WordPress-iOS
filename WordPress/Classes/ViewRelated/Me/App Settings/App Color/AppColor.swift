import SwiftUI

enum AppColor {

    // MARK: API

    static private(set) var color: Color = savedColor ?? defaultColor {
        didSet {
            savedColor = color
        }
    }

    static var uiColor: UIColor {
        .init(color)
    }

    static var defaultColor: Color {
        switch appConfig {
        case .wordpress:
            return .muriel(.wordPressBlue)
        case .jetpack:
            return .muriel(.jetpackGreen)
        case .unknown:
            return .red
        }
    }

    static func update(with newColor: Color) {
        color = newColor
    }

    // MARK: Helpers

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

    private static var defaultsKey: String {
        "\(appConfig.rawValue).AppColorComponents"
    }

    private static var appConfig: AppConfig {
        if AppConfiguration.isWordPress {
            return .wordpress
        } else if AppConfiguration.isJetpack {
            return .jetpack
        } else {
            assertionFailure("unsupported configuration")
            return .unknown
        }
    }

    private enum AppConfig: String {
        case wordpress = "Wordpress"
        case jetpack = "Jetpack"
        case unknown = "Unknown"
    }

}

private extension Color {
    static func muriel(_ name: MurielColorName) -> Self {
        .init(UIColor.muriel(color: .init(name: name)))
    }
}
