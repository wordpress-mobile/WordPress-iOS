import Foundation

struct MigrationAnalyticsTracker {

    // MARK: - Track Method

    func track(_ event: MigrationEvent, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        WPAnalytics.track(event)
    }

    // MARK: - Content Import

    func trackContentImportEligibility(eligible: Bool) {
        let properties = ["eligible": String(eligible)]
        self.track(.contentImportEligibility, properties: properties)
    }

    func trackContentImportSucceeded() {
        self.track(.contentImportSucceeded)
    }

    func trackContentImportFailed(reason: String) {
        let properties = ["error_type": reason]
        self.track(.contentImportFailed, properties: properties)
    }

    // MARK: - WordPress Migration Eligibility

    /// Tracks an event representing the WordPress migratable state.
    /// If WordPress is not installed, nothing is tracked.
    func trackWordPressMigrationEligibility() {
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

