import Foundation

final class SiteStatsNudgeState {
    private let nudges: [GrowAudienceCell.HintType] = [.social, .bloggingReminders]
    private let siteId: NSNumber

    init(siteId: NSNumber) {
        self.siteId = siteId
    }

    // Returns the first uncompleted nudge
    var nudgeToDisplay: GrowAudienceCell.HintType? {
        for nudge in nudges where !isNudgeCompleted(nudge) {
            return nudge
        }
        return nil
    }

    func markNudgeAsCompleted(_ nudge: GrowAudienceCell.HintType) {
        UserDefaults.standard.set(true, forKey: userDefaultsKey(for: nudge))
    }

    func isNudgeCompleted(_ nudge: GrowAudienceCell.HintType) -> Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey(for: nudge))
    }
}

// MARK: - Private Methods
private extension SiteStatsNudgeState {
    // Nudge completed key per site
    func userDefaultsKey(for nudge: GrowAudienceCell.HintType) -> String {
        "StatsInsights-\(siteId.intValue)-\(nudge.rawValue)-nudge-completed"
    }
}
