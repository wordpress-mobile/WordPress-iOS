public struct StatsTopReferrersTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalReferrerViewsCount: Int
    public let otherReferrerViewsCount: Int

    public var referrers: [StatsReferrer]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                referrers: [StatsReferrer],
                totalReferrerViewsCount: Int,
                otherReferrerViewsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.referrers = referrers
        self.totalReferrerViewsCount = totalReferrerViewsCount
        self.otherReferrerViewsCount = otherReferrerViewsCount
    }
}

public struct StatsReferrer {
    public let title: String
    public let viewsCount: Int
    public let url: URL?
    public let iconURL: URL?

    public var children: [StatsReferrer]
    public var isSpam = false

    public init(title: String,
                viewsCount: Int,
                url: URL?,
                iconURL: URL?,
                children: [StatsReferrer]) {
        self.title = title
        self.viewsCount = viewsCount
        self.url = url
        self.iconURL = iconURL
        self.children = children
    }
}

extension StatsTopReferrersTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/referrers"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let referrers = unwrappedDays["groups"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let totalClicks = unwrappedDays["total_views"] as? Int ?? 0
        let otherClicks = unwrappedDays["other_views"] as? Int ?? 0

        self.period = period
        self.periodEndDate = date
        self.totalReferrerViewsCount = totalClicks
        self.otherReferrerViewsCount = otherClicks
        self.referrers = referrers.compactMap { StatsReferrer(jsonDictionary: $0) }
    }
}

extension StatsReferrer {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let title = jsonDictionary["name"] as? String
            else {
                return nil
        }

        // The shape of API reply here is _almost_ a perfectly fractal tree structure.
        // However, sometimes the keys for children/parents representing the same values change, hence this
        // rether ugly hack.
        let viewsCount: Int

        if let views = jsonDictionary["total"] as? Int {
            viewsCount = views
        } else if let views = jsonDictionary["views"] as? Int {
            viewsCount = views
        } else {
            // If neither key is present, this is a malformed response.
            return nil
        }

        let children: [StatsReferrer]

        if let childrenJSON = jsonDictionary["results"] as? [[String: AnyObject]] {
            children = childrenJSON.compactMap { StatsReferrer(jsonDictionary: $0) }
        } else if let childrenJSON = jsonDictionary["children"] as? [[String: AnyObject]] {
            children = childrenJSON.compactMap { StatsReferrer(jsonDictionary: $0) }
        } else {
            children = []
        }

        let icon = jsonDictionary["icon"] as? String
        let urlString = jsonDictionary["url"] as? String

        self.title = title
        self.viewsCount = viewsCount
        self.url = urlString.flatMap { URL(string: $0) }
        self.iconURL = icon.flatMap { URL(string: $0) }
        self.children = children
    }
}
