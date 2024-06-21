public struct StatsPublishedPostsTimeIntervalData {
    public let periodEndDate: Date
    public let period: StatsPeriodUnit

    public let publishedPosts: [StatsTopPost]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                publishedPosts: [StatsTopPost]) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.publishedPosts = publishedPosts
    }
}

extension StatsPublishedPostsTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "posts/"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard let posts = jsonDictionary["posts"] as? [[String: AnyObject]] else {
            return nil
        }

        self.periodEndDate = date
        self.period = period
        self.publishedPosts = posts.compactMap { StatsTopPost(postsJSONDictionary: $0) }
    }
}

private extension StatsTopPost {
    init?(postsJSONDictionary: [String: AnyObject]) {
        guard
            let id = postsJSONDictionary["ID"] as? Int,
            let title = postsJSONDictionary["title"] as? String,
            let urlString = postsJSONDictionary["URL"] as? String
            else {
                return nil
        }

        self.postID = id
        self.title = title
        self.postURL = URL(string: urlString)
        self.viewsCount = 0
        self.kind = .unknown
    }
}
