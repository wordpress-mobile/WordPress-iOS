import Foundation

public struct StatsTopCityTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalViewsCount: Int
    public let otherViewsCount: Int

    public let cities: [City]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                cities: [City],
                totalViewsCount: Int,
                otherViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.cities = cities
        self.totalViewsCount = totalViewsCount
        self.otherViewsCount = otherViewsCount
    }

    public struct City {
        public let name: String
        public let countryCode: String
        public let coordinates: Coordinates?
        public let viewsCount: Int

        public init(name: String,
                    countryCode: String,
                    coordinates: Coordinates?,
                    viewsCount: Int) {
            self.name = name
            self.countryCode = countryCode
            self.coordinates = coordinates
            self.viewsCount = viewsCount
        }

        public struct Coordinates {
            public let latitude: String
            public let longitude: String

            public init(latitude: String, longitude: String) {
                self.latitude = latitude
                self.longitude = longitude
            }
        }
    }
}

extension StatsTopCityTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        "stats/location-views/city"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let summary = jsonDictionary["summary"] as? [String: AnyObject],
            let citiesViews = Bamboozled.parseArray(summary["views"])
        else {
            return nil
        }

        let totalViews = summary["total_views"] as? Int ?? 0
        let otherViews = summary["other_views"] as? Int ?? 0

        self.periodEndDate = date
        self.period = period

        self.totalViewsCount = totalViews
        self.otherViewsCount = otherViews
        self.cities = citiesViews.compactMap { City(jsonDictionary: $0) }
    }
}

extension StatsTopCityTimeIntervalData.City {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let location = jsonDictionary["location"] as? String,
            let viewsCount = jsonDictionary["views"] as? Int,
            let countryCode = jsonDictionary["country_code"] as? String
        else {
            return nil
        }

        let coordinates: Coordinates?
        if let coordinatesDict = jsonDictionary["coordinates"] as? [String: AnyObject],
           let latitude = coordinatesDict["latitude"] as? String,
           let longitude = coordinatesDict["longitude"] as? String {
            coordinates = Coordinates(latitude: latitude, longitude: longitude)
        } else {
            coordinates = nil
        }

        self.name = location
        self.countryCode = countryCode
        self.coordinates = coordinates
        self.viewsCount = viewsCount
    }
}
