import Foundation

public struct StatsTopCityTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalViewsCount: Int
    public let otherViewsCount: Int

    public let cities: [StatsCity]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                cities: [StatsCity],
                totalViewsCount: Int,
                otherViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.cities = cities
        self.totalViewsCount = totalViewsCount
        self.otherViewsCount = otherViewsCount
    }
}

public struct StatsCity {
    public let name: String
    public let code: String?
    public let countryCode: String
    public let regionName: String?
    public let viewsCount: Int

    public init(name: String,
                code: String?,
                countryCode: String,
                regionName: String?,
                viewsCount: Int) {
        self.name = name
        self.code = code
        self.countryCode = countryCode
        self.regionName = regionName
        self.viewsCount = viewsCount
    }
}

extension StatsTopCityTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        "stats/location-views/city"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let citiesViews = Bamboozled.parseArray(unwrappedDays["views"])
        else {
            return nil
        }

        let cityInfo = jsonDictionary["city-info"] as? [String: AnyObject] ?? [:]
        let totalViews = unwrappedDays["total_views"] as? Int ?? 0
        let otherViews = unwrappedDays["other_views"] as? Int ?? 0

        self.periodEndDate = date
        self.period = period

        self.totalViewsCount = totalViews
        self.otherViewsCount = otherViews
        self.cities = citiesViews.compactMap { StatsCity(jsonDictionary: $0, cityInfo: cityInfo) }
    }
}

extension StatsCity {
    init?(jsonDictionary: [String: AnyObject], cityInfo: [String: AnyObject]) {
        guard
            let viewsCount = jsonDictionary["views"] as? Int,
            let countryCode = jsonDictionary["country_code"] as? String
        else {
            return nil
        }

        let cityCode = jsonDictionary["city_code"] as? String
        let regionName = jsonDictionary["region"] as? String

        let name: String

        if let code = cityCode,
           let cityDict = cityInfo[code] as? [String: AnyObject],
           let cityName = cityDict["city_full"] as? String {
            name = cityName
        } else if let cityName = jsonDictionary["city"] as? String {
            name = cityName
        } else if let code = cityCode {
            name = code
        } else {
            return nil
        }

        self.viewsCount = viewsCount
        self.code = cityCode
        self.countryCode = countryCode
        self.regionName = regionName
        self.name = name
    }
}
