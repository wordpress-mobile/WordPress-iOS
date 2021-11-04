import Foundation

protocol UnifiedAboutTrackerEvent {
    var name: String { get }
    var properties: [String: String] { get }
}

/// Analytics tracker for the unified about flows.
///
public class UnifiedAboutTracker {
    typealias TrackCallback = (_ eventName: String, _ properties: [String: String]) -> Void

    /// The tracking callback.
    ///
    private let trackCallback: TrackCallback

    // MARK: -

    init(trackCallback: @escaping TrackCallback) {
        self.trackCallback = trackCallback
    }

    // MARK: - Tracking

    func track(_ event: UnifiedAboutTrackerEvent) {
        trackCallback(event.name, event.properties)
    }

    // MARK: - Supported Events

    public struct ScreenShownEvent: UnifiedAboutTrackerEvent {
        let name = "about_screen_shown"
        let properties = [String: String]()
    }

    public struct ScreenDismissedEvent: UnifiedAboutTrackerEvent {
        let name = "about_screen_dismissed"
        let properties = [String: String]()
    }

    public struct ButtonPressedEvent: UnifiedAboutTrackerEvent {
        enum Button: String, CaseIterable {
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

        private static let buttonPropertyKey = "button"

        let name = "about_screen_button_tapped"
        let button: Button

        var properties: [String: String] {
            [ButtonPressedEvent.buttonPropertyKey: button.rawValue]
        }
    }
}
