public struct StatsDotComFollowersInsight: Codable {
    public let dotComFollowersCount: Int
    public let topDotComFollowers: [StatsFollower]

    public init (dotComFollowersCount: Int,
                 topDotComFollowers: [StatsFollower]) {
        self.dotComFollowersCount = dotComFollowersCount
        self.topDotComFollowers = topDotComFollowers
    }

    private enum CodingKeys: String, CodingKey {
        case dotComFollowersCount = "total_wpcom"
        case topDotComFollowers = "subscribers"
    }
}

extension StatsDotComFollowersInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["type": "wpcom",
                "max": String(maxCount)]
    }

    public static var pathComponent: String {
        return "stats/followers"
    }

    fileprivate static let dateFormatter = ISO8601DateFormatter()
}

public struct StatsFollower: Codable, Equatable {
    public let id: String?
    public let name: String
    public let subscribedDate: Date
    public let avatarURL: URL?

    public init(name: String,
                subscribedDate: Date,
                avatarURL: URL?,
                id: String? = nil) {
        self.name = name
        self.subscribedDate = subscribedDate
        self.avatarURL = avatarURL
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "label"
        case subscribedDate = "date_subscribed"
        case avatarURL = "avatar"
    }
}

extension StatsFollower {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        if let id = try? container.decodeIfPresent(Int.self, forKey: .id) {
            self.id = "\(id)"
        } else if let id = try? container.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = nil
        }

        let avatar = try? container.decodeIfPresent(String.self, forKey: .avatarURL)
        if let avatar, var components = URLComponents(string: avatar) {
            components.query = "d=mm&s=60" // to get a properly-sized avatar.
            self.avatarURL = components.url
        } else {
            self.avatarURL = nil
        }

        let dateString = try container.decode(String.self, forKey: .subscribedDate)
        if let date = StatsDotComFollowersInsight.dateFormatter.date(from: dateString) {
            self.subscribedDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .subscribedDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
    }

    init?(jsonDictionary: [String: AnyObject]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder()
            self = try decoder.decode(StatsFollower.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
