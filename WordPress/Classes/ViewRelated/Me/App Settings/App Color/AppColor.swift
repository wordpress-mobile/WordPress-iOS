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
            savedAccent = accent
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
            return AppLocalizedString("Default", comment: "Title for the Default app accent color")
        case .green:
            return AppLocalizedString("Green", comment: "Title for the Green app accent color")
        case .blue:
            return AppLocalizedString("Blue", comment: "Title for the Blue app accent color")
        case .orange:
            return AppLocalizedString("Orange", comment: "Title for the Orange app accent color")
        case .purple:
            return AppLocalizedString("Purple", comment: "Title for the Purple app accent color")
        case .pink:
            return AppLocalizedString("Pink", comment: "Title for the Pink app accent color")
        }
    }

    var color: Color {
        switch self {
        case .`default`:
            return AppColor.defaultAccentColor
        case .green:
            return .muriel(.green)
        case .blue:
            return .muriel(.blue)
        case .orange:
            return .muriel(.orange)
        case .purple:
            return .muriel(.purple)
        case .pink:
            return .muriel(.pink)
        }
    }
}

private extension Color {
    static func muriel(_ name: MurielColorName) -> Self {
        .init(UIColor.muriel(color: .init(name: name)))
    }
}
