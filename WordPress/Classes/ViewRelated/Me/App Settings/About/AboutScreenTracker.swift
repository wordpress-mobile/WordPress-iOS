import Foundation

class AboutScreenTracker {
    enum Event: String {
        case screenShown = "about_screen_shown"
        case screenDismissed = "about_screen_dismissed"
        case buttonPressed = "about_screen_button_tapped"

        enum Screen: String {
            case main
            case legalAndMore = "legal_and_more"
        }

        enum Button: String, CaseIterable {
            case dismiss
            case rateUs = "rate_us"
            case share
            case twitter
            case blog
            case legal
            case automatticFamily = "automattic_family"
            case workWithUs = "work_with_us"

            case termsOfService = "terms_of_service"
            case privacyPolicy = "privacy_policy"
            case sourceCode = "source_code"
            case acknowledgements
        }

        enum PropertyName: String {
            case screen
            case button
        }
    }

    typealias TrackCallback = (String, _ properties: [String: Any]) -> Void

    private let track: TrackCallback

    init(track: @escaping TrackCallback = WPAnalytics.trackString) {
        self.track = track
    }

    private func track(_ event: Event, properties: [String: Any]) {
        track(event.rawValue, properties)
    }

    func buttonPressed(_ button: Event.Button, properties: [String: Any]? = nil) {
        track(.buttonPressed, properties: properties ?? [Event.PropertyName.button.rawValue: button.rawValue])
    }

    func screenShown(_ screen: Event.Screen) {
        track(.screenShown, properties: [Event.PropertyName.screen.rawValue: screen.rawValue])
    }

    func screenDismissed(_ screen: Event.Screen) {
        track(.screenDismissed, properties: [Event.PropertyName.screen.rawValue: screen.rawValue])
    }
}
