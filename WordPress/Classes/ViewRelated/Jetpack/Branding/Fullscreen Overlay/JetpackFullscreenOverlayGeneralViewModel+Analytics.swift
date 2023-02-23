import Foundation
import AutomatticTracks

extension JetpackFullscreenOverlayGeneralViewModel {

    // MARK: Private Enum Decleration

    private enum DismissalType: String {
        case close, `continue`
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

    func didDisplayOverlay() {
        WPAnalytics.track(.jetpackFullscreenOverlayDisplayed, properties: defaultProperties)
    }

    func didTapLink() {
        guard let urlString = learnMoreButtonURL,
              let url = URL(string: urlString) else {
            return
        }

        let source = "jetpack_overlay_\(analyticsSource)"
        coordinator?.navigateToLinkRoute(url: url, source: source)
        WPAnalytics.track(.jetpackFullscreenOverlayLinkTapped, properties: defaultProperties)
    }

    func didTapPrimary() {
        // Try to export WordPress data to a shared location before redirecting the user.
        ContentMigrationCoordinator.shared.startAndDo { [weak self] _ in
            guard let self = self else {
                return
            }
            JetpackRedirector.redirectToJetpack()
            WPAnalytics.track(.jetpackFullscreenOverlayButtonTapped, properties: self.defaultProperties)
        }
    }

    func didTapClose() {
        trackOverlayDismissed(dismissalType: .close)
    }

    func didTapSecondary() {
        trackOverlayDismissed(dismissalType: .continue)
        onWillDismiss?()
    }

    // MARK: Helpers

    private func trackOverlayDismissed(dismissalType: DismissalType) {
        var properties = defaultProperties
        properties[Self.dismiassalTypePropertyKey] = dismissalType.rawValue
        WPAnalytics.track(.jetpackFullscreenOverlayDismissed, properties: properties)
    }
}
