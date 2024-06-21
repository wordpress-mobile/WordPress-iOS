public struct StatsAllTimesInsight: Codable {
    public let postsCount: Int
    public let viewsCount: Int
    public let bestViewsDay: Date
    public let visitorsCount: Int
    public let bestViewsPerDayCount: Int

    public init(postsCount: Int,
                viewsCount: Int,
                bestViewsDay: Date,
                visitorsCount: Int,
                bestViewsPerDayCount: Int) {
        self.postsCount = postsCount
        self.viewsCount = viewsCount
        self.bestViewsDay = bestViewsDay
        self.visitorsCount = visitorsCount
        self.bestViewsPerDayCount = bestViewsPerDayCount
    }

    private enum CodingKeys: String, CodingKey {
        case postsCount = "posts"
        case viewsCount = "views"
        case bestViewsDay = "views_best_day"
        case visitorsCount = "visitors"
        case bestViewsPerDayCount = "views_best_day_total"
    }

    private enum RootKeys: String, CodingKey {
        case stats
    }
}

extension StatsAllTimesInsight: StatsInsightData {
    public init (from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootKeys.self)
        let container = try rootContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .stats)

        self.postsCount = (try? container.decodeIfPresent(Int.self, forKey: .postsCount)) ?? 0
        self.bestViewsPerDayCount = (try? container.decodeIfPresent(Int.self, forKey: .bestViewsPerDayCount)) ?? 0
        self.visitorsCount = (try? container.decodeIfPresent(Int.self, forKey: .visitorsCount)) ?? 0

        self.viewsCount = (try? container.decodeIfPresent(Int.self, forKey: .viewsCount)) ?? 0
        let bestViewsDayString = try container.decodeIfPresent(String.self, forKey: .bestViewsDay) ?? ""
        self.bestViewsDay = StatsAllTimesInsight.dateFormatter.date(from: bestViewsDayString) ?? Date()
    }

    // MARK: -
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
