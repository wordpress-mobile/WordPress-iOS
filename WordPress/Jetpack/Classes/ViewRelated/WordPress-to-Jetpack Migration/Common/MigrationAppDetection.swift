import Foundation

enum WordPressInstallationState {
    case wordPressNotInstalled
    case wordPressInstalledNotMigratable
    case wordPressInstalledAndMigratable

    var isWordPressInstalled: Bool {
        return self != .wordPressNotInstalled
    }
}

struct MigrationAppDetection {

    static func getWordPressInstallationState() -> WordPressInstallationState {
        let tracker = MigratatableStateTracker()

        if UIApplication.shared.canOpen(app: .wordpressMigrationV1) {
            tracker.trackMigratable()
            return .wordPressInstalledAndMigratable
        }

        if UIApplication.shared.canOpen(app: .wordpress) {
            tracker.trackNotMigratable()
            return .wordPressInstalledNotMigratable
        }

        return .wordPressNotInstalled
    }
}

struct MigratatableStateTracker {

    private static let eventName = "jpmigration_wordpressapp_detected"

    private func track(_ event: AnalyticsEvent) {
        WPAnalytics.track(event)
    }

    private func event(_ eventName: String, properties: [String: String]) -> AnalyticsEvent {
        AnalyticsEvent(name: eventName, properties: properties)
    }

    func trackMigratable() {
        track(event(Self.eventName, properties: ["compatible": "true"]))
    }

    func trackNotMigratable() {
        track(event(Self.eventName, properties: ["compatible": "false"]))
    }
}
