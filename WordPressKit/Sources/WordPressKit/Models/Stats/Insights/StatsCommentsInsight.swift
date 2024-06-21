public struct StatsCommentsInsight: Codable {
    public let topPosts: [StatsTopCommentsPost]
    public let topAuthors: [StatsTopCommentsAuthor]

    public init(topPosts: [StatsTopCommentsPost],
                topAuthors: [StatsTopCommentsAuthor]) {
        self.topPosts = topPosts
        self.topAuthors = topAuthors
    }

    private enum CodingKeys: String, CodingKey {
        case topPosts = "posts"
        case topAuthors = "authors"
    }
}

extension StatsCommentsInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/comments"
    }
}

public struct StatsTopCommentsAuthor: Codable {
    public let name: String
    public let commentCount: Int
    public let iconURL: URL?

    public init(name: String,
                commentCount: Int,
                iconURL: URL?) {
        self.name = name
        self.commentCount = commentCount
        self.iconURL = iconURL
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case commentCount = "comments"
        case iconURL = "gravatar"
    }
}

public struct StatsTopCommentsPost: Codable {
    public let name: String
    public let postID: String
    public let commentCount: Int
    public let postURL: URL?

    public init(name: String,
                postID: String,
                commentCount: Int,
                postURL: URL?) {
        self.name = name
        self.postID = postID
        self.commentCount = commentCount
        self.postURL = postURL
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case postID = "id"
        case commentCount = "comments"
        case postURL = "link"
    }
}

private extension StatsTopCommentsAuthor {
    init(name: String, avatar: String?, commentCount: Int) {
        let url: URL?

        if let avatar, var components = URLComponents(string: avatar) {
            components.query = "d=mm&s=60" // to get a properly-sized avatar.
            url = components.url
        } else {
            url = nil
        }

        self.name = name
        self.commentCount = commentCount
        self.iconURL = url
    }
}

public extension StatsTopCommentsAuthor {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let commentCount: Int
        if let comments = try? container.decodeIfPresent(String.self, forKey: .commentCount) {
            commentCount = Int(comments) ?? 0
        } else {
            commentCount = 0
        }
        let iconURL = try container.decodeIfPresent(String.self, forKey: .iconURL)

        self.init(name: name, avatar: iconURL, commentCount: commentCount)
    }
}

public extension StatsTopCommentsPost {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let postID = try container.decode(String.self, forKey: .postID)
        let commentCount: Int
        if let comments = try? container.decodeIfPresent(String.self, forKey: .commentCount) {
            commentCount = Int(comments) ?? 0
        } else {
            commentCount = 0
        }
        let postURL = try container.decodeIfPresent(URL.self, forKey: .postURL)

        self.init(name: name, postID: postID, commentCount: commentCount, postURL: postURL)
    }
}
