public struct StatsAnnualAndMostPopularTimeInsight: Codable {
    /// - A `DateComponents` object with one field populated: `weekday`.
    public let mostPopularDayOfWeek: DateComponents
    public let mostPopularDayOfWeekPercentage: Int

    /// - A `DateComponents` object with one field populated: `hour`.
    public let mostPopularHour: DateComponents
    public let mostPopularHourPercentage: Int
    public let years: [Year]?

    private enum CodingKeys: String, CodingKey {
        case mostPopularHour = "highest_hour"
        case mostPopularHourPercentage = "highest_hour_percent"
        case mostPopularDayOfWeek = "highest_day_of_week"
        case mostPopularDayOfWeekPercentage = "highest_day_percent"
        case years
    }

    public struct Year: Codable {
        public let year: String
        public let totalPosts: Int
        public let totalWords: Int
        public let averageWords: Double
        public let totalLikes: Int
        public let averageLikes: Double
        public let totalComments: Int
        public let averageComments: Double
        public let totalImages: Int
        public let averageImages: Double

        private enum CodingKeys: String, CodingKey {
            case year
            case totalPosts = "total_posts"
            case totalWords = "total_words"
            case averageWords = "avg_words"
            case totalLikes = "total_likes"
            case averageLikes = "avg_likes"
            case totalComments = "total_comments"
            case averageComments = "avg_comments"
            case totalImages = "total_images"
            case averageImages = "avg_images"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            year = try container.decode(String.self, forKey: .year)
            totalPosts = (try? container.decodeIfPresent(Int.self, forKey: .totalPosts)) ?? 0
            totalWords = (try? container.decode(Int.self, forKey: .totalWords)) ?? 0
            averageWords = (try? container.decode(Double.self, forKey: .averageWords)) ?? 0
            totalLikes = (try? container.decode(Int.self, forKey: .totalLikes)) ?? 0
            averageLikes = (try? container.decode(Double.self, forKey: .averageLikes)) ?? 0
            totalComments = (try? container.decode(Int.self, forKey: .totalComments)) ?? 0
            averageComments = (try? container.decode(Double.self, forKey: .averageComments)) ?? 0
            totalImages = (try? container.decode(Int.self, forKey: .totalImages)) ?? 0
            averageImages = (try? container.decode(Double.self, forKey: .averageImages)) ?? 0
        }
    }
}

extension StatsAnnualAndMostPopularTimeInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/insights"
    }
}

extension StatsAnnualAndMostPopularTimeInsight {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let years = try container.decodeIfPresent([Year].self, forKey: .years)
        let highestHour = try container.decode(Int.self, forKey: .mostPopularHour)
        let highestHourPercentageValue = try container.decode(Double.self, forKey: .mostPopularHourPercentage)
        let highestDayOfWeek = try container.decode(Int.self, forKey: .mostPopularDayOfWeek)
        let highestDayOfWeekPercentageValue = try container.decode(Double.self, forKey: .mostPopularDayOfWeekPercentage)

        let mappedWeekday: ((Int) -> Int) = {
            // iOS Calendar system is `1-based` and uses Sunday as the first day of the week.
            // The data returned from WP.com is `0-based` and uses Monday as the first day of the week.
            // This maps the WP.com data to iOS format.
            return $0 == 6 ? 0 : $0 + 2
        }

        let weekDayComponent = DateComponents(weekday: mappedWeekday(highestDayOfWeek))
        let hourComponents = DateComponents(hour: highestHour)

        self.mostPopularDayOfWeek = weekDayComponent
        self.mostPopularDayOfWeekPercentage = Int(highestDayOfWeekPercentageValue.rounded())
        self.mostPopularHour = hourComponents
        self.mostPopularHourPercentage = Int(highestHourPercentageValue.rounded())
        self.years = years
    }
}
