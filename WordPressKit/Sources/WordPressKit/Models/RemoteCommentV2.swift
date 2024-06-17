/// Captures the JSON structure for Comments returned from API v2 endpoint.
public struct RemoteCommentV2 {
    public var commentID: Int
    public var postID: Int
    public var parentID: Int = 0
    public var authorID: Int
    public var authorName: String?
    public var authorEmail: String? // only available in edit context
    public var authorURL: String?
    public var authorIP: String? // only available in edit context
    public var authorUserAgent: String? // only available in edit context
    public var authorAvatarURL: String?
    public var date: Date
    public var content: String
    public var rawContent: String? // only available in edit context
    public var link: String
    public var status: String
    public var type: String
}

// MARK: - Decodable

extension RemoteCommentV2: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case post
        case parent
        case author
        case authorName = "author_name"
        case authorEmail = "author_email"
        case authorURL = "author_url"
        case authorIP = "author_ip"
        case authorUserAgent = "author_user_agent"
        case date = "date_gmt" // take the gmt version, as the other `date` parameter doesn't provide timezone information.
        case content
        case authorAvatarURLs = "author_avatar_urls"
        case link
        case status
        case type
    }

    enum ContentCodingKeys: String, CodingKey {
        case rendered
        case raw
    }

    enum AuthorAvatarCodingKeys: String, CodingKey {
        case size96 = "96" // this is the default size for avatar URL in API v1.1.
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.commentID = try container.decode(Int.self, forKey: .id)
        self.postID = try container.decode(Int.self, forKey: .post)
        self.parentID = try container.decode(Int.self, forKey: .parent)
        self.authorID = try container.decode(Int.self, forKey: .author)
        self.authorName = try container.decode(String.self, forKey: .authorName)
        self.authorEmail = try container.decodeIfPresent(String.self, forKey: .authorEmail)
        self.authorURL = try container.decode(String.self, forKey: .authorURL)
        self.authorIP = try container.decodeIfPresent(String.self, forKey: .authorIP)
        self.authorUserAgent = try container.decodeIfPresent(String.self, forKey: .authorUserAgent)
        self.link = try container.decode(String.self, forKey: .link)
        self.type = try container.decode(String.self, forKey: .type)

        // since `date_gmt` is already in GMT timezone, manually add the timezone string to make the rfc3339 formatter happy (or it will throw otherwise).
        guard let dateString = try? container.decode(String.self, forKey: .date),
              let date = NSDate.with(wordPressComJSONString: dateString + "+00:00") else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date parsing failed")
        }
        self.date = date

        let contentContainer = try container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content)
        self.rawContent = try contentContainer.decodeIfPresent(String.self, forKey: .raw)
        self.content = try contentContainer.decode(String.self, forKey: .rendered)

        let remoteStatus = try container.decode(String.self, forKey: .status)
        self.status = Self.status(from: remoteStatus)

        let avatarContainer = try container.nestedContainer(keyedBy: AuthorAvatarCodingKeys.self, forKey: .authorAvatarURLs)
        self.authorAvatarURL = try avatarContainer.decode(String.self, forKey: .size96)
    }

    /// Maintain parity with the client-side comment statuses. Refer to `CommentServiceRemoteREST:statusWithRemoteStatus`.
    private static func status(from remoteStatus: String) -> String {
        switch remoteStatus {
        case "unapproved":
            return "hold"
        case "approved":
            return "approve"
        default:
            return remoteStatus
        }
    }
}
