import Foundation

/// Singleton class to contain site related information for Stats.
///
@objc class SiteStatsInformation: NSObject {

    // MARK: - Properties
    typealias SiteInsights = [String: [Int]]
    private let userDefaultsInsightTypesKey = "StatsInsightTypes"
    @objc static var sharedInstance: SiteStatsInformation = SiteStatsInformation()
    private override init() {}

    @objc var siteID: NSNumber?
    @objc var siteTimeZone: TimeZone?
    @objc var oauth2Token: String?

    func updateTimeZone() {
        let context = ContextManager.shared.mainContext

        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: context) else {
            return
        }

        siteTimeZone = blog.timeZone
    }

    func timeZoneMatchesDevice() -> Bool {
        return siteTimeZone == TimeZone.current
    }
}

extension SiteStatsInformation {

    func getCurrentSiteInsights(_ userDefaults: UserDefaults = UserDefaults.standard) -> [InsightType] {

        guard let siteID = siteID?.stringValue else {
            return InsightType.defaultInsights
        }

        // Get Insights from User Defaults, and extract those for the current site.
        let allSitesInsights = userDefaults.object(forKey: userDefaultsInsightTypesKey) as? [SiteInsights] ?? []
        let values = allSitesInsights.first { $0.keys.first == siteID }?.values.first
        return InsightType.typesForValues(values ?? InsightType.defaultInsightsValues)
    }

    func saveCurrentSiteInsights(_ insightsCards: [InsightType], _ userDefaults: UserDefaults = UserDefaults.standard) {

        guard let siteID = siteID?.stringValue else {
            return
        }

        let insightTypesValues = InsightType.valuesForTypes(insightsCards)
        let currentSiteInsights = [siteID: insightTypesValues]

        // Remove existing dictionary from array, and add the updated one.
        let currentInsights = (userDefaults.object(forKey: userDefaultsInsightTypesKey) as? [SiteInsights] ?? [])
        var updatedInsights = currentInsights.filter { $0.keys.first != siteID }
        updatedInsights.append(currentSiteInsights)

        userDefaults.set(updatedInsights, forKey: userDefaultsInsightTypesKey)
    }

    // Updates any insights that were written in UserDefaults,
    // in order to update the default order and remove the .customize card from the list
    func upgradeInsights() {
        let savedInsights = getCurrentSiteInsights().filter { $0 != .growAudience && $0 != .customize }

        guard savedInsights == InsightType.oldDefaultInsights else {
            // remove the .customize card regardless the list is default or custom
            let noCustomizeInsights = getCurrentSiteInsights().filter { $0 != .customize }
            saveCurrentSiteInsights(noCustomizeInsights)
            return
        }
        // re-add the pinned cards, but get rid of .customize
        let newInsights = getCurrentSiteInsights().filter { $0 == .growAudience } + InsightType.defaultInsights
        saveCurrentSiteInsights(newInsights)
    }
}
