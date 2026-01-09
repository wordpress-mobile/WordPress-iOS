import Foundation

public struct StatsTopRegionTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalViewsCount: Int
    public let otherViewsCount: Int

    public let regions: [StatsRegion]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                regions: [StatsRegion],
                totalViewsCount: Int,
                otherViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.regions = regions
        self.totalViewsCount = totalViewsCount
        self.otherViewsCount = otherViewsCount
    }
}

public struct StatsRegion {
    public let name: String
    public let code: String
    public let countryCode: String
    public let viewsCount: Int

    public init(name: String,
                code: String,
                countryCode: String,
                viewsCount: Int) {
        self.name = name
        self.code = code
        self.countryCode = countryCode
        self.viewsCount = viewsCount
    }
}

extension StatsTopRegionTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        "stats/location-views/region"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let regionsViews = Bamboozled.parseArray(unwrappedDays["views"])
        else {
            return nil
        }

        let regionInfo = jsonDictionary["region-info"] as? [String: AnyObject] ?? [:]
        let totalViews = unwrappedDays["total_views"] as? Int ?? 0
        let otherViews = unwrappedDays["other_views"] as? Int ?? 0

        self.periodEndDate = date
        self.period = period

        self.totalViewsCount = totalViews
        self.otherViewsCount = otherViews
        self.regions = regionsViews.compactMap { StatsRegion(jsonDictionary: $0, regionInfo: regionInfo) }
    }
}

extension StatsRegion {
    init?(jsonDictionary: [String: AnyObject], regionInfo: [String: AnyObject]) {
        guard
            let viewsCount = jsonDictionary["views"] as? Int,
            let regionCode = jsonDictionary["region_code"] as? String,
            let countryCode = jsonDictionary["country_code"] as? String
        else {
            return nil
        }

        let name: String

        if let regionDict = regionInfo[regionCode] as? [String: AnyObject],
           let regionName = regionDict["region_full"] as? String {
            name = regionName
        } else {
            name = regionCode
        }

        self.viewsCount = viewsCount
        self.code = regionCode
        self.countryCode = countryCode
        self.name = name
    }
}
