import Foundation
import AutomatticTracks

extension JetpackFullscreenOverlayGeneralViewModel {

    // MARK: Private Enum Decleration

    private enum DismissalType: String {
        case close, swipe, `continue`
    }

    // MARK: Static Property Keys

    private static let phasePropertyKey = "phase"
    private static let sourcePropertyKey = "source"
    private static let dismiassalTypePropertyKey = "dismissal_type"

    // MARK: Private Computed Property

    private var defaultProperties: [String: String] {
        return [
            Self.phasePropertyKey: phase.rawValue,
            Self.sourcePropertyKey: source.rawValue
        ]
    }

    // MARK: Analytics Implementation

    func trackOverlayDisplayed() {
        WPAnalytics.track(.jetpackFullscreenOverlayDisplayed, properties: defaultProperties)
    }

    func trackLearnMoreTapped() {
        WPAnalytics.track(.jetpackFullscreenOverlayLinkTapped, properties: defaultProperties)
    }

    func trackSwitchButtonTapped() {
        WPAnalytics.track(.jetpackFullscreenOverlayButtonTapped, properties: defaultProperties)
    }

    func trackCloseButtonTapped() {
        trackOverlayDismissed(dismissalType: .close)
    }

    func trackOverlaySwippedDown() {
        trackOverlayDismissed(dismissalType: .swipe)
    }

    func trackContinueButtonTapped() {
        trackOverlayDismissed(dismissalType: .continue)
    }

    // MARK: Helpers

    private func trackOverlayDismissed(dismissalType: DismissalType) {
        var properties = defaultProperties
        properties[Self.dismiassalTypePropertyKey] = dismissalType.rawValue
        WPAnalytics.track(.jetpackFullscreenOverlayDismissed, properties: properties)
    }
}
