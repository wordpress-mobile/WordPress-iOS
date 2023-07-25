import Foundation

final class StatsInsightsCache {
    static let shared = StatsInsightsCache()

    private var cache: [CacheKey: StatsInsightData] = [:]

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
}
