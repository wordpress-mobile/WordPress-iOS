import Foundation
import WordPressKit
import CocoaLumberjack

final class StatsInsightsCache {
    static let shared = StatsInsightsCache()

    private var cache: [CacheKey: StatsInsightData] = [:]
    private var lastRefreshDates: [NSNumber: Date] = [:]

    // MARK: - Accessing Cached Data

    func getValue<T: StatsInsightData>(record: Record, siteID: NSNumber) -> T? {
        let key = CacheKey(record: record, siteID: siteID)
        return cache[key] as? T
    }

    func setValue<T: StatsInsightData>(_ value: T, record: Record, siteID: NSNumber) {
        let key = CacheKey(record: record, siteID: siteID)
        cache[key] = value
    }

    func removeAll() {
        cache.removeAll()
    }

    // MARK: - Expiration

    var isExpired: Bool {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
              let date = lastRefreshDates[siteID] else {
                  return true
              }

        let interval = Date().timeIntervalSince(date)
        let expired = interval > Constants.cacheTTL

        let intervalLogMessage = "(\(String(format: "%.2f", interval))s since last refresh)"
        DDLogInfo("Stats: Insights cache for site \(siteID) has \(expired ? "" : "not ")expired \(intervalLogMessage).")

        return expired
    }

    func setLastRefreshDate(_ date: Date, forSiteID siteID: NSNumber) {
        lastRefreshDates[siteID] = Date()
    }

    // MARK: - Helpers

    enum Record: Hashable {
        case lastPostInsight
        case allTimeStats
        case annualAndMostPopularTime
        case publicizeFollowers
        case todaysStats
        case postingActivity
        case topTagsAndCategories
        case topCommentsInsight
        case dotComFollowers
        case emailFollowers
    }

    private struct CacheKey: Hashable {
        let record: Record
        let siteID: NSNumber
    }

    private enum Constants {
        static let cacheTTL: TimeInterval = 300 // 5 minutes
    }
}
