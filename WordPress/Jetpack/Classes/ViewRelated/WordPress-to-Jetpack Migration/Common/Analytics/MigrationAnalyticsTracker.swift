import Foundation

struct MigrationAnalyticsTracker {

    // MARK: - Track Method

    func track(_ event: MigrationEvent, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        WPAnalytics.track(event)
    }

    // MARK: - WordPress Migration Eligibility

    /// Tracks an event representing the WordPress migratable state.
    /// If WordPress is not installed, nothing is tracked.
    func trackWordPressMigrationEligibility(compatible: Bool) {
        let state = MigrationAppDetection.getWordPressInstallationState()
        switch state {
        case .wordPressInstalledAndMigratable:
            let properties = ["compatible": "true"]
            self.track(.wordPressDetected, properties: properties)
        case .wordPressInstalledNotMigratable:
            let properties = ["compatible": "false"]
            self.track(.wordPressDetected, properties: properties)
        default:
            break
        }
    }

    // MARK: - Types

    typealias Properties = [String: String]
}

