public struct StatsTopClicksTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalClicksCount: Int
    public let otherClicksCount: Int

    public let clicks: [StatsClick]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                clicks: [StatsClick],
                totalClicksCount: Int,
                otherClicksCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.clicks = clicks
        self.totalClicksCount = totalClicksCount
        self.otherClicksCount = otherClicksCount
    }
}

public struct StatsClick {
    public let title: String
    public let clicksCount: Int
    public let clickedURL: URL?
    public let iconURL: URL?

    public let children: [StatsClick]

    public init(title: String,
                clicksCount: Int,
                clickedURL: URL?,
                iconURL: URL?,
                children: [StatsClick]) {
        self.title = title
        self.clicksCount = clicksCount
        self.clickedURL = clickedURL
        self.iconURL = iconURL
        self.children = children
    }
}

extension StatsTopClicksTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/clicks"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let clicks = unwrappedDays["clicks"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let totalClicks = unwrappedDays["total_clicks"] as? Int ?? 0
        let otherClicks = unwrappedDays["other_clicks"] as? Int ?? 0

        self.period = period
        self.periodEndDate = date
        self.totalClicksCount = totalClicks
        self.otherClicksCount = otherClicks
        self.clicks = clicks.compactMap { StatsClick(jsonDictionary: $0) }
    }
}

extension StatsClick {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let title = jsonDictionary["name"] as? String,
            let clicksCount = jsonDictionary["views"] as? Int
            else {
                return nil
        }

        let children: [StatsClick]

        if let childrenJSON = jsonDictionary["children"] as? [[String: AnyObject]] {
            children = childrenJSON.compactMap { StatsClick(jsonDictionary: $0) }
        } else {
            children = []
        }

        let icon = jsonDictionary["icon"] as? String
        let urlString = jsonDictionary["url"] as? String

        self.title = title
        self.clicksCount = clicksCount
        self.clickedURL = urlString.flatMap { URL(string: $0) }
        self.iconURL = icon.flatMap { URL(string: $0) }
        self.children = children
    }
}
