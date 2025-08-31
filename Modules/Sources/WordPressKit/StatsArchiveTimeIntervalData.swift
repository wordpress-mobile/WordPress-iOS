import Foundation

public struct StatsArchiveTimeIntervalData {
    public let period: StatsPeriodUnit
    public let unit: StatsPeriodUnit?
    public let periodEndDate: Date
    public let summary: [String: [StatsArchiveItem]]

    public init(period: StatsPeriodUnit,
                unit: StatsPeriodUnit? = nil,
                periodEndDate: Date,
                summary: [String: [StatsArchiveItem]]) {
        self.period = period
        self.unit = unit
        self.periodEndDate = periodEndDate
        self.summary = summary
    }
}

public struct StatsArchiveItem {
    public let href: String
    public let value: String
    public let views: Int

    public init(href: String, value: String, views: Int) {
        self.href = href
        self.value = value
        self.views = views
    }
}

extension StatsArchiveTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/archives"
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return ["max": String(maxCount)]
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        self.init(date: date, period: period, unit: nil, jsonDictionary: jsonDictionary)
    }

    public init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject]) {
        guard let summary = jsonDictionary["summary"] as? [String: AnyObject] else {
            return nil
        }

        self.period = period
        self.unit = unit
        self.periodEndDate = date
        self.summary = {
            var map: [String: [StatsArchiveItem]] = [:]
            for (key, value) in summary {
                let items = (value as? [[String: AnyObject]])?.compactMap {
                    StatsArchiveItem(jsonDictionary: $0)
                } ?? []
                if !items.isEmpty {
                    map[key] = items
                }
            }
            return map
        }()
    }
}

private extension StatsArchiveItem {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let href = jsonDictionary["href"] as? String,
            let value = jsonDictionary["value"] as? String,
            let views = jsonDictionary["views"] as? Int
        else {
            return nil
        }

        self.href = href
        self.value = value
        self.views = views
    }
}
