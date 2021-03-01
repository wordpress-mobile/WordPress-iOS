import UIKit

/// Encapsulates UIUserInterfaceStyle getting and setting for the app's
/// main window. Allows users to override the interface style for the app.
///
struct AppAppearance {
    /// The default interface style if not overridden
    static let `default`: UIUserInterfaceStyle = .unspecified

    private static var currentWindow: UIWindow? {
        return WordPressAppDelegate.shared?.window
    }

    /// The current user interface style used by the app
    static var current: UIUserInterfaceStyle {
        return currentWindow?.overrideUserInterfaceStyle ?? .unspecified
    }

    /// Overrides the app's current appeareance with the specified style.
    /// If no style is provided, the app's appearance will be overridden
    /// by any preference that may be currently saved in user defaults.
    ///
    static func overrideAppearance(with style: UIUserInterfaceStyle? = nil) {
        guard let window = currentWindow else {
            return
        }

        if let style = style {
            trackEvent(with: style)
            savedStyle = style
        }

        window.overrideUserInterfaceStyle = style ?? savedStyle
    }

    // MARK: - Tracks

    private static func trackEvent(with style: UIUserInterfaceStyle) {
        WPAnalytics.track(.appSettingsAppearanceChanged, properties: [Keys.styleTracksProperty: style.appearanceDescription])
    }

    // MARK: - Persistence

    /// Saves or gets the current interface style preference.
    /// If no style has been saved, returns the default.
    ///
    private static var savedStyle: UIUserInterfaceStyle {
        get {
            guard let rawValue = UserDefaults.standard.value(forKey: Keys.appAppearanceDefaultsKey) as? Int,
                let style = UIUserInterfaceStyle(rawValue: rawValue) else {
                    return AppAppearance.default
            }

            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.appAppearanceDefaultsKey)
        }
    }

    enum Keys {
        static let styleTracksProperty = "style"
        static let appAppearanceDefaultsKey = "app-appearance-override"
    }
}

extension UIUserInterfaceStyle {
    var appearanceDescription: String {
        switch self {
        case .light:
            return NSLocalizedString("Light", comment: "Title for the app appearance setting for light mode")
        case .dark:
            return NSLocalizedString("Dark", comment: "Title for the app appearance setting for dark mode")
        case .unspecified:
            return NSLocalizedString("System default", comment: "Title for the app appearance setting (light / dark mode) that uses the system default value")
        @unknown default:
            return ""
        }
    }

    static var allStyles: [UIUserInterfaceStyle] {
        return [.light, .dark, .unspecified]
    }
}
