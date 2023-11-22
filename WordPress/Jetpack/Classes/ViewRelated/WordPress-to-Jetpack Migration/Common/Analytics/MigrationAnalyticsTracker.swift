import Foundation

struct MigrationAnalyticsTracker {
    // MARK: - Track Method

    func track(_ event: MigrationEvent, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        WPAnalytics.track(event)
    }

    // MARK: - Content Export

    func trackContentExportEligibility(eligible: Bool) {
        let properties = ["eligible": String(eligible)]
        self.track(.contentExportEligibility, properties: properties)
    }

    func trackContentExportSucceeded(hasBlogs: Bool) {
        var properties: [String: String] = [:]
        if !hasBlogs {
            properties["no_sites"] = "true"
        }
        self.track(.contentExportSucceeded, properties: properties)
    }

    func trackContentExportFailed(reason: String, hasBlogs: Bool) {
        var properties = ["error_type": reason]
        if !hasBlogs {
            properties["no_sites"] = "true"
        }
        self.track(.contentExportFailed, properties: properties)
    }

    // MARK: - Content Import

    func trackContentImportEligibility(params: ContentImportEventParams) {
        let properties = [
            "eligible": String(params.eligible),
            "featureFlagEnabled": String(params.featureFlagEnabled),
            "compatibleWordPressInstalled": String(params.compatibleWordPressInstalled),
            "migrationState": String(params.migrationState.rawValue),
            "loggedIn": String(params.loggedIn)
        ]
        self.track(.contentImportEligibility, properties: properties)
    }

    func trackContentImportSucceeded() {
        /// Refresh the account metadata so subsequent analytics calls are linked to the user.
        WPAnalytics.refreshMetadata()
        self.track(.contentImportSucceeded)
    }

    func trackContentImportFailed(reason: String) {
        let properties = ["error_type": reason]
        self.track(.contentImportFailed, properties: properties)
    }

    struct ContentImportEventParams {
        let eligible: Bool
        let featureFlagEnabled: Bool
        let compatibleWordPressInstalled: Bool
        let migrationState: MigrationState
        let loggedIn: Bool
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
