import Foundation
import WordPressKit

final class StatsPediodCache {
    static let shared = StatsPediodCache()

    private var cache: [CacheKey: StatsTimeIntervalData] = [:]

    func getValue<T: StatsTimeIntervalData>(record: Record, date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit, siteID: NSNumber) -> T? {
        let key = makeKey(record: record, date: date, period: period, unit: unit, siteID: siteID)
        return cache[key] as? T
    }

    func setValue<T: StatsTimeIntervalData>(_ value: T, record: Record, siteID: NSNumber) {
        let key = makeKey(record: record, date: value.periodEndDate, period: value.period, unit: value.unit ?? value.period, siteID: siteID)
        cache[key] = value
    }

    func removeAll() {
        cache.removeAll()
    }

    private func makeKey(record: Record, date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit, siteID: NSNumber) -> CacheKey {
        let date = Calendar.current.startOfDay(for: date)
        return CacheKey(record: record, date: date, period: period, unit: unit, siteID: siteID)
    }

    enum Record: Hashable {
        case timeIntervalsSummary
        case totalsSummary
        case topPostsAndPages
        case topReferrers
        case topClicks
        case topPublished
        case topAuthors
        case topSearchTerms
        case topCountries
        case topVideos
        case topFileDownloads
    }

    private struct CacheKey: Hashable {
        let record: Record
        let date: Date
        let period: StatsPeriodUnit
        let unit: StatsPeriodUnit
        let siteID: NSNumber
    }
}

final class StatsCache: NSObject {
    @objc class func clearCaches() {
        StatsPediodCache.shared.removeAll()
        StatsInsightsCache.shared.removeAll()
    }
}
