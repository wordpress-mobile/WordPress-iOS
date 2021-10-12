import Foundation

final class SiteStatsNudgeState {
    private let suggestionsOrder: [GrowAudienceCell.HintType] = [.social, .bloggingReminders]
    private let siteId: NSNumber

    init(siteId: NSNumber) {
        self.siteId = siteId
    }
}

// MARK: - Private Methods
private extension SiteStatsNudgeState {
    // Post sharing enabled state key per site
    var userDefaultsPostSharingEnabledKey: String {
        let siteID = siteId.intValue
        let key = "StatsInsightsPostSharingEnabled"
        return key + "-\(siteID)"
    }

    // Blogging reminders enabled state key per site
    var userDefaultsBloggingRemindersEnabledKey: String {
        let siteID = siteId.intValue
        let key = "StatsInsightsBloggingRemindersEnabled"
        return key + "-\(siteID)"
    }
}
