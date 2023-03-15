import SwiftUI

enum AppColor {

    enum Accent: String, CaseIterable {
        case `default`
        case green
        case blue
        case orange
        case purple
        case pink
    }

    // MARK: API

    static private(set) var accent: Accent = savedAccent ?? .default {
        didSet {
            if accent != oldValue {
                savedAccent = accent

                NotificationCenter.default
                    .post(name: .appColorDidUpdateAccent, object: accent)
            }
        }
    }

    static var accentColor: Color {
        accent.color
    }

    static func updateAccent(with newAccent: Accent) {
        accent = newAccent
    }

    // MARK: Helpers

    private static var savedAccent: Accent? {
        get {
            guard let rawValue = defaults.string(forKey: savedAccentKey) else {
                return nil
            }
            return Accent(rawValue: rawValue)
        }
        set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: savedAccentKey)
            }
        }
    }

    private static var defaults: UserDefaults {
        .init(suiteName: WPAppGroupName) ?? .standard
    }

    private static var savedAccentKey: String {
        "\(appConfig.rawValue).AppColor.Accent"
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

    private static var defaultAccentColor: Color {
        switch appConfig {
        case .wordpress:
            return .muriel(.wordPressBlue)
        case .jetpack:
            return .muriel(.jetpackGreen)
        case .unknown:
            return .red
        }
    }

}

extension AppColor.Accent: Identifiable, CustomStringConvertible {
    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .`default`:
            return AppLocalizedString("color.default", comment: "Title for the `Default` app accent color")
        case .green:
            return AppLocalizedString("color.green", comment: "Title for the `Green` app accent color")
        case .blue:
            return AppLocalizedString("color.blue", comment: "Title for the `Blue` app accent color")
        case .orange:
            return AppLocalizedString("color.orange", comment: "Title for the `Orange` app accent color")
        case .purple:
            return AppLocalizedString("color.purple", comment: "Title for the `Purple` app accent color")
        case .pink:
            return AppLocalizedString("color.pink", comment: "Title for the `Pink` app accent color")
        }
    }

    var color: Color {
        switch self {
        case .`default`:
            return AppColor.defaultAccentColor
        case .green:
            return .dynamic(
                light: .muriel(.green),
                dark: .muriel(.green)
            )
        case .blue:
            return .dynamic(
                light: .muriel(.blue),
                dark: .muriel(.blue)
            )
        case .orange:
            return .dynamic(
                light: .muriel(.orange),
                dark: .muriel(.orange)
            )
        case .purple:
            return .dynamic(
                light: .muriel(.purple),
                dark: .muriel(.purple)
            )
        case .pink:
            return .dynamic(
                light: .muriel(.pink),
                dark: .muriel(.pink)
            )
        }
    }
}

extension Foundation.Notification.Name {
    static let appColorDidUpdateAccent = Self("appColorDidUpdateAccent")
}

private extension Color {
    static func muriel(
        _ name: MurielColorName,
        shade: MurielColorShade = .shade50
    ) -> Self {
        .init(
            UIColor.muriel(color: .init(name: name, shade: shade))
        )
    }

    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor(
            dynamicProvider: {
                $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            })
        )
    }
}
