public struct StatsPublicizeInsight: Codable {
    public let publicizeServices: [StatsPublicizeService]

    public init(publicizeServices: [StatsPublicizeService]) {
        self.publicizeServices = publicizeServices
    }

    private enum CodingKeys: String, CodingKey {
        case publicizeServices = "services"
    }
}

extension StatsPublicizeInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/publicize"
    }
}

public struct StatsPublicizeService: Codable {
    public let name: String
    public let followers: Int
    public let iconURL: URL?

    public init(name: String,
                followers: Int,
                iconURL: URL?) {
        self.name = name
        self.followers = followers
        self.iconURL = iconURL
    }

    private enum CodingKeys: String, CodingKey {
        case name = "service"
        case followers
    }
}

private extension StatsPublicizeService {
    init(name: String, followers: Int) {
        let niceName: String
        let icon: URL?

        switch name {
        case "facebook":
            niceName = "Facebook"
            icon = URL(string: "https://secure.gravatar.com/blavatar/2343ec78a04c6ea9d80806345d31fd78?s=60")
        case "twitter":
            niceName = "Twitter"
            icon = URL(string: "https://secure.gravatar.com/blavatar/7905d1c4e12c54933a44d19fcd5f9356?s=60")
        case "tumblr":
            niceName = "Tumblr"
            icon = URL(string: "https://secure.gravatar.com/blavatar/84314f01e87cb656ba5f382d22d85134?s=60")
        case "google_plus":
            niceName = "Google+"
            icon = URL(string: "https://secure.gravatar.com/blavatar/4a4788c1dfc396b1f86355b274cc26b3?s=60")
        case "linkedin":
            niceName = "LinkedIn"
            icon = URL(string: "https://secure.gravatar.com/blavatar/f54db463750940e0e7f7630fe327845e?s=60")
        case "path":
            niceName = "path"
            icon = URL(string: "https://secure.gravatar.com/blavatar/3a03c8ce5bf1271fb3760bb6e79b02c1?s=60")
        default:
            niceName = name
            icon = nil
        }

        self.name = niceName
        self.followers = followers
        self.iconURL = icon
    }
}

public extension StatsPublicizeService {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let followers = (try? container.decodeIfPresent(Int.self, forKey: .followers)) ?? 0

        self.init(name: name, followers: followers)
    }
}
