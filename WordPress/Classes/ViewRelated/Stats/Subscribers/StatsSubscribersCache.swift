import Foundation
import WordPressKit

final class StatsSubscribersCache {
    static let shared = StatsSubscribersCache()

    private var cache: [CacheKey: Any] = [:]

    func getValue<T: Any>(key: CacheKey) -> T? {
        return cache[key] as? T
    }

    func setValue<T: Any>(_ value: T, key: CacheKey) {
        cache[key] = value
    }

    func removeAll() {
        cache.removeAll()
    }

    struct CacheKey: Hashable {
        let record: StatSection
        let key: String
        let siteID: NSNumber

        static func emailsSummary(quantity: Int, sortField: String, sortOrder: String, siteId: NSNumber) -> CacheKey {
            return .init(record: .subscribersEmailsSummary, key: "\(quantity) \(sortField) \(sortOrder)", siteID: siteId)
        }

        static func chartSummary(unit: String, siteId: NSNumber) -> CacheKey {
            return .init(record: .subscribersChart, key: unit, siteID: siteId)
        }

        static func subscribersList(quantity: Int, siteId: NSNumber) -> CacheKey {
            return .init(record: .subscribersList, key: "\(quantity)", siteID: siteId)
        }
    }
}
