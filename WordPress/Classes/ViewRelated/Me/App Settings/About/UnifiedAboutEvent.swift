import Foundation

public enum UnifiedAboutEvent {
    case screenShown
    case screenDismissed
    case buttonPressed(button: Button)

    public enum Button: String, CaseIterable {
        case dismiss
        case rateUs = "rate_us"
        case share
        case twitter
        case legal
        case automatticFamily = "automattic_family"
        case workWithUs = "work_with_us"

        // App buttons
        case appDayone = "app_dayone"
        case appJetpack = "app_jetpack"
        case appPocketcasts = "app_pocketcasts"
        case appSimplenote = "app_simplenote"
        case appTumblr = "app_tumblr"
        case appWoo = "app_woo"
        case appWordpress = "app_wordpress"
    }

    public static let buttonPropertyKey = "button"

    public var name: String {
        switch self {
        case .screenShown:
            return "about_screen_shown"
        case .screenDismissed:
            return "about_screen_dismissed"
        case .buttonPressed:
            return "about_screen_button_tapped"
        }
    }

    public var properties: [String: String] {
        switch self {
        case .screenShown:
            return [:]
        case .screenDismissed:
            return [:]
        case .buttonPressed(let button):
            return [UnifiedAboutEvent.buttonPropertyKey: button.rawValue]
        }
    }
}
