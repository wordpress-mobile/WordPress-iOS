public struct StatsEmailFollowersInsight: Codable {
    public let emailFollowersCount: Int
    public let topEmailFollowers: [StatsFollower]

    public init(emailFollowersCount: Int,
                topEmailFollowers: [StatsFollower]) {
        self.emailFollowersCount = emailFollowersCount
        self.topEmailFollowers = topEmailFollowers
    }

    private enum CodingKeys: String, CodingKey {
        case emailFollowersCount = "total_email"
        case topEmailFollowers = "subscribers"
    }
}

extension StatsEmailFollowersInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["type": "email",
                "max": String(maxCount)]
    }

    public static var pathComponent: String {
        return "stats/followers"
    }
}
