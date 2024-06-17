public struct StatsLastPostInsight: Equatable, Decodable {
    public let title: String
    public let url: URL
    public let publishedDate: Date
    public let likesCount: Int
    public let commentsCount: Int
    public private(set) var viewsCount: Int = 0
    public let postID: Int
    public let featuredImageURL: URL?

    public init(title: String,
                url: URL,
                publishedDate: Date,
                likesCount: Int,
                commentsCount: Int,
                viewsCount: Int,
                postID: Int,
                featuredImageURL: URL?) {
        self.title = title
        self.url = url
        self.publishedDate = publishedDate
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.viewsCount = viewsCount
        self.postID = postID
        self.featuredImageURL = featuredImageURL
    }
}

extension StatsLastPostInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["order_by": "date",
                "number": "1",
                "type": "post",
                "fields": "ID, title, URL, discussion, like_count, date, featured_image"]
    }

    public static var pathComponent: String {
        return "posts/"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        self.init(jsonDictionary: jsonDictionary, views: 0)
    }

    // MARK: -

    private static let dateFormatter = ISO8601DateFormatter()

    public init?(jsonDictionary: [String: AnyObject], views: Int) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder()
            self = try decoder.decode(StatsLastPostInsight.self, from: jsonData)
            self.viewsCount = views
        } catch {
            return nil
        }
    }
}

extension StatsLastPostInsight {
    private enum CodingKeys: String, CodingKey {
        case title
        case url = "URL"
        case publishedDate = "date"
        case likesCount = "like_count"
        case commentsCount
        case postID = "ID"
        case featuredImageURL = "featured_image"
        case discussion
    }

    private enum DiscussionKeys: String, CodingKey {
        case commentsCount = "comment_count"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title).trimmingCharacters(in: .whitespaces).stringByDecodingXMLCharacters()
        url = try container.decode(URL.self, forKey: .url)
        let dateString = try container.decode(String.self, forKey: .publishedDate)
        guard let date = StatsLastPostInsight.dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .publishedDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        publishedDate = date
        likesCount = (try? container.decodeIfPresent(Int.self, forKey: .likesCount)) ?? 0
        postID = try container.decode(Int.self, forKey: .postID)
        featuredImageURL = try? container.decodeIfPresent(URL.self, forKey: .featuredImageURL)

        let discussionContainer = try container.nestedContainer(keyedBy: DiscussionKeys.self, forKey: .discussion)
        commentsCount = (try? discussionContainer.decodeIfPresent(Int.self, forKey: .commentsCount)) ?? 0
    }
}
