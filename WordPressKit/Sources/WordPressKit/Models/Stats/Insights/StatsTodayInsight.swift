public struct StatsTodayInsight: Codable {
    public let viewsCount: Int
    public let visitorsCount: Int
    public let likesCount: Int
    public let commentsCount: Int

    public init(viewsCount: Int,
                visitorsCount: Int,
                likesCount: Int,
                commentsCount: Int) {
        self.viewsCount = viewsCount
        self.visitorsCount = visitorsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

extension StatsTodayInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/summary"
    }

    private enum CodingKeys: String, CodingKey {
        case viewsCount = "views"
        case visitorsCount = "visitors"
        case likesCount = "likes"
        case commentsCount = "comments"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        viewsCount = (try? container.decodeIfPresent(Int.self, forKey: .viewsCount)) ?? 0
        visitorsCount = (try? container.decodeIfPresent(Int.self, forKey: .visitorsCount)) ?? 0
        likesCount = (try? container.decodeIfPresent(Int.self, forKey: .likesCount)) ?? 0
        commentsCount = (try? container.decodeIfPresent(Int.self, forKey: .commentsCount)) ?? 0
    }
}
