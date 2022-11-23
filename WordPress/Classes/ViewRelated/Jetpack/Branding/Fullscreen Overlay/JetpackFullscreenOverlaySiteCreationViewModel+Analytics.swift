import Foundation
import AutomatticTracks

extension JetpackFullscreenOverlaySiteCreationViewModel {

    // MARK: Private Enum Decleration

    private enum DismissalType: String {
        case close, `continue`
    }

    // MARK: Static Property Keys

    private static let phasePropertyKey = "site_creation_phase"
    private static let sourcePropertyKey = "source"
    private static let dismiassalTypePropertyKey = "dismissal_type"

    // MARK: Private Computed Property

    private var defaultProperties: [String: String] {
        return [
            Self.phasePropertyKey: phase.rawValue,
            Self.sourcePropertyKey: source
        ]
    }

    // MARK: Analytics Implementation

    func trackOverlayDisplayed() {
        WPAnalytics.track(.jetpackSiteCreationOverlayDisplayed, properties: defaultProperties)
    }

    func trackLearnMoreTapped() {
        assert(false, "Not implemnted because it should never be called.")
    }

    func trackSwitchButtonTapped() {
        WPAnalytics.track(.jetpackSiteCreationOverlayButtonTapped, properties: defaultProperties)
    }

    func trackCloseButtonTapped() {
        trackOverlayDismissed(dismissalType: .close)
    }

    func trackContinueButtonTapped() {
        trackOverlayDismissed(dismissalType: .continue)
    }

    // MARK: Helpers

    private func trackOverlayDismissed(dismissalType: DismissalType) {
        var properties = defaultProperties
        properties[Self.dismiassalTypePropertyKey] = dismissalType.rawValue
        WPAnalytics.track(.jetpackSiteCreationOverlayDismissed, properties: properties)
    }
}
