public struct StatsTopCountryTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalViewsCount: Int
    public let otherViewsCount: Int

    public let countries: [StatsCountry]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                countries: [StatsCountry],
                totalViewsCount: Int,
                otherViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.countries = countries
        self.totalViewsCount = totalViewsCount
        self.otherViewsCount = otherViewsCount
    }
}

public struct StatsCountry {
    public let name: String
    public let code: String
    public let viewsCount: Int

    public init(name: String,
                code: String,
                viewsCount: Int) {
        self.name = name
        self.code = code
        self.viewsCount = viewsCount
    }
}

extension StatsTopCountryTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/country-views"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let countriesViews = unwrappedDays["views"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let countryInfo = jsonDictionary["country-info"] as? [String: AnyObject] ?? [:]
        let totalViews = unwrappedDays["total_views"] as? Int ?? 0
        let otherViews = unwrappedDays["other_views"] as? Int ?? 0

        self.periodEndDate = date
        self.period = period

        self.totalViewsCount = totalViews
        self.otherViewsCount = otherViews
        self.countries = countriesViews.compactMap { StatsCountry(jsonDictionary: $0, countryInfo: countryInfo) }
    }

}

extension StatsCountry {
    init?(jsonDictionary: [String: AnyObject], countryInfo: [String: AnyObject]) {
        guard
            let viewsCount = jsonDictionary["views"] as? Int,
            let countryCode = jsonDictionary["country_code"] as? String
            else {
                return nil
        }

        let name: String

        if
            let countryDict = countryInfo[countryCode] as? [String: AnyObject],
            let countryName = countryDict["country_full"] as? String {
            name = countryName
        } else {
            name = countryCode
        }

        self.viewsCount = viewsCount
        self.code = countryCode
        self.name = name
    }
}
