import Foundation

struct JetpackOverlayFrequencyTracker {
    let phase: JetpackFeaturesRemovalCoordinator.GeneralPhase // TODO: Do we need this?
    let source: JetpackFeaturesRemovalCoordinator.OverlaySource

    func shouldShow() -> Bool {
        // TODO: To be implemented
        // Show once for login and app open
        // Always show for card
        // Check frequency for features
        return true
    }

    func track() {
        // TODO: To be implemented
        // record that the overlay was displayed
    }
}
