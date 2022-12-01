import Foundation

struct MigratableStateTracker {

    private static let eventName = "migration_wordpressapp_detected"

    private func track(_ event: AnalyticsEvent) {
        WPAnalytics.track(event)
    }

    private func event(_ eventName: String, properties: [String: String]) -> AnalyticsEvent {
        AnalyticsEvent(name: eventName, properties: properties)
    }

    /// Tracks an event representing the WordPress migratable state.
    /// If WordPress is not installed, nothing is tracked.
    func track() {
        let installationState = MigrationAppDetection.getWordPressInstallationState()
        switch installationState {
        case .wordPressInstalledAndMigratable:
            self.trackMigratable()
        case .wordPressInstalledNotMigratable:
            self.trackNotMigratable()
        default:
            break
        }
    }

    private func trackMigratable() {
        track(event(Self.eventName, properties: ["compatible": "true"]))
    }

    private func trackNotMigratable() {
        track(event(Self.eventName, properties: ["compatible": "false"]))
    }
}
