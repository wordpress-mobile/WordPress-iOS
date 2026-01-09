import Foundation

public struct StatsTopRegionTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalViewsCount: Int
    public let otherViewsCount: Int

    public let regions: [Region]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                regions: [Region],
                totalViewsCount: Int,
                otherViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.regions = regions
        self.totalViewsCount = totalViewsCount
        self.otherViewsCount = otherViewsCount
    }

    public struct Region {
        public let name: String
        public let countryCode: String
        public let viewsCount: Int

        public init(name: String,
                    countryCode: String,
                    viewsCount: Int) {
            self.name = name
            self.countryCode = countryCode
            self.viewsCount = viewsCount
        }
    }
}

extension StatsTopRegionTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        "stats/location-views/region"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let summary = jsonDictionary["summary"] as? [String: AnyObject],
            let regionsViews = Bamboozled.parseArray(summary["views"])
        else {
            return nil
        }

        let totalViews = summary["total_views"] as? Int ?? 0
        let otherViews = summary["other_views"] as? Int ?? 0

        self.periodEndDate = date
        self.period = period

        self.totalViewsCount = totalViews
        self.otherViewsCount = otherViews
        self.regions = regionsViews.compactMap { Region(jsonDictionary: $0) }
    }
}

extension StatsTopRegionTimeIntervalData.Region {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let location = jsonDictionary["location"] as? String,
            let viewsCount = jsonDictionary["views"] as? Int,
            let countryCode = jsonDictionary["country_code"] as? String
        else {
            return nil
        }

        self.name = location
        self.countryCode = countryCode
        self.viewsCount = viewsCount
    }
}
