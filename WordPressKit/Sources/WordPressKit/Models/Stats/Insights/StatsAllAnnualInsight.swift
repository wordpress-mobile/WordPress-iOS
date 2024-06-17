public struct StatsAllAnnualInsight: Codable {
    public let allAnnualInsights: [StatsAnnualInsight]

    public init(allAnnualInsights: [StatsAnnualInsight]) {
        self.allAnnualInsights = allAnnualInsights
    }

    private enum CodingKeys: String, CodingKey {
        case allAnnualInsights = "years"
    }
}

public struct StatsAnnualInsight: Codable {
    public let year: Int
    public let totalPostsCount: Int
    public let totalWordsCount: Int
    public let averageWordsCount: Double
    public let totalLikesCount: Int
    public let averageLikesCount: Double
    public let totalCommentsCount: Int
    public let averageCommentsCount: Double
    public let totalImagesCount: Int
    public let averageImagesCount: Double

    public init(year: Int,
                totalPostsCount: Int,
                totalWordsCount: Int,
                averageWordsCount: Double,
                totalLikesCount: Int,
                averageLikesCount: Double,
                totalCommentsCount: Int,
                averageCommentsCount: Double,
                totalImagesCount: Int,
                averageImagesCount: Double) {
        self.year = year
        self.totalPostsCount = totalPostsCount
        self.totalWordsCount = totalWordsCount
        self.averageWordsCount = averageWordsCount
        self.totalLikesCount = totalLikesCount
        self.averageLikesCount = averageLikesCount
        self.totalCommentsCount = totalCommentsCount
        self.averageCommentsCount = averageCommentsCount
        self.totalImagesCount = totalImagesCount
        self.averageImagesCount = averageImagesCount
    }

    private enum CodingKeys: String, CodingKey {
        case year
        case totalPostsCount = "total_posts"
        case totalWordsCount = "total_words"
        case averageWordsCount = "avg_words"
        case totalLikesCount = "total_likes"
        case averageLikesCount = "avg_likes"
        case totalCommentsCount = "total_comments"
        case averageCommentsCount = "avg_comments"
        case totalImagesCount = "total_images"
        case averageImagesCount = "avg_images"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let year = Int(try container.decode(String.self, forKey: .year)) {
            self.year = year
        } else {
            throw DecodingError.dataCorruptedError(forKey: .year, in: container, debugDescription: "Year cannot be parsed into number.")
        }
        totalPostsCount = (try? container.decodeIfPresent(Int.self, forKey: .totalPostsCount)) ?? 0
        totalWordsCount = (try? container.decodeIfPresent(Int.self, forKey: .totalWordsCount)) ?? 0
        averageWordsCount = (try? container.decodeIfPresent(Double.self, forKey: .averageWordsCount)) ?? 0
        totalLikesCount = (try? container.decodeIfPresent(Int.self, forKey: .totalLikesCount)) ?? 0
        averageLikesCount = (try? container.decodeIfPresent(Double.self, forKey: .averageLikesCount)) ?? 0
        totalCommentsCount = (try? container.decodeIfPresent(Int.self, forKey: .totalCommentsCount)) ?? 0
        averageCommentsCount = (try? container.decodeIfPresent(Double.self, forKey: .averageCommentsCount)) ?? 0
        totalImagesCount = (try? container.decodeIfPresent(Int.self, forKey: .totalImagesCount)) ?? 0
        averageImagesCount = (try? container.decodeIfPresent(Double.self, forKey: .averageImagesCount)) ?? 0
    }
}

extension StatsAllAnnualInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/insights"
    }
}
