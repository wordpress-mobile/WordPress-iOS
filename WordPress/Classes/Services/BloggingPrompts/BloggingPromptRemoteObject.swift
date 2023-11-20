/// Encapsulates a single blogging prompt object from the v3 API.
struct BloggingPromptRemoteObject {
    let promptID: Int
    let text: String
    let attribution: String
    let date: Date
    let answered: Bool
    let answeredUsersCount: Int
    let answeredUserAvatarURLs: [URL]
    let answeredLink: URL?
    let answeredLinkText: String
    let bloganuaryId: String?
}

// MARK: - Decodable

extension BloggingPromptRemoteObject: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case attribution
        case date
        case answered
        case answeredUsersCount = "answered_users_count"
        case answeredUserAvatarURLs = "answered_users_sample"
        case answeredLink = "answered_link"
        case answeredLinkText = "answered_link_text"
        case bloganuaryId = "bloganuary_id"
    }

    /// meta structure to simplify decoding logic for user avatar objects.
    /// this is intended to be private.
    private struct UserAvatar: Codable {
        var avatar: String
    }

    /// Used to format the fetched object's date string to a date.
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.promptID = try container.decode(Int.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.attribution = try container.decode(String.self, forKey: .attribution)
        self.answered = try container.decode(Bool.self, forKey: .answered)
        self.date = Self.dateFormatter.date(from: try container.decode(String.self, forKey: .date)) ?? Date()
        self.answeredUsersCount = try container.decode(Int.self, forKey: .answeredUsersCount)

        let userAvatars = try container.decode([UserAvatar].self, forKey: .answeredUserAvatarURLs)
        self.answeredUserAvatarURLs = userAvatars.compactMap { URL(string: $0.avatar) }

        self.answeredLink = {
            guard let linkURLString = try? container.decode(String.self, forKey: .answeredLink),
                  let answeredLinkURL = URL(string: linkURLString) else {
                return nil
            }
            return answeredLinkURL
        }()

        self.answeredLinkText = try container.decode(String.self, forKey: .answeredLinkText)

        self.bloganuaryId = {
            guard let remoteBloganuaryId = try? container.decode(String.self, forKey: .bloganuaryId),
                  !remoteBloganuaryId.isEmpty else {
                return nil
            }
            return remoteBloganuaryId
        }()
    }
}
