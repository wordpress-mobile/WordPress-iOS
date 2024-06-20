public struct StatsTotalsSummaryData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date
    public let viewsCount: Int
    public let visitorsCount: Int
    public let likesCount: Int
    public let commentsCount: Int

    public init(
        period: StatsPeriodUnit,
        periodEndDate: Date,
        viewsCount: Int,
        visitorsCount: Int,
        likesCount: Int,
        commentsCount: Int
    ) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.viewsCount = viewsCount
        self.visitorsCount = visitorsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

extension StatsTotalsSummaryData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/summary"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        self.period = period
        self.periodEndDate = date
        self.visitorsCount = jsonDictionary["visitors"] as? Int ?? 0
        self.viewsCount = jsonDictionary["views"] as? Int ?? 0
        self.likesCount = jsonDictionary["likes"] as? Int ?? 0
        self.commentsCount = jsonDictionary["comments"] as? Int ?? 0
    }
}
