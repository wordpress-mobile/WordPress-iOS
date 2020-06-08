import UIKit

/// Encapsulates UIUserInterfaceStyle getting and setting for the app's
/// main window. Allows users to override the interface style for the app.
///
@available(iOS 13.0, *)
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

    /// Overrides the app's current appeareance with the specified style
    static func overrideAppearance(with style: UIUserInterfaceStyle) {
        guard let window = currentWindow else {
            return
        }

        WPAnalytics.track(.appSettingsAppearanceChanged, properties: ["style": style.appearanceDescription])

        window.overrideUserInterfaceStyle = style
    }
}

@available(iOS 13.0, *)
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
