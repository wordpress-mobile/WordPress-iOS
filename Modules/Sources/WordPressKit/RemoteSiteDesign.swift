import Foundation

public struct RemoteSiteDesigns: Codable {
    public let designs: [RemoteSiteDesign]
    public let categories: [RemoteSiteDesignCategory]

    enum CodingKeys: String, CodingKey {
        case designs
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        designs = try map.decode([RemoteSiteDesign].self, forKey: .designs)
        categories = try map.decode([RemoteSiteDesignCategory].self, forKey: .categories)
    }

    public init() {
        self.init(designs: [], categories: [])
    }

    public init(designs: [RemoteSiteDesign], categories: [RemoteSiteDesignCategory]) {
        self.designs = designs
        self.categories = categories
    }
}

public struct RemoteSiteDesign: Codable {
    public let slug: String
    public let title: String
    public let demoURL: String
    public let screenshot: String?
    public let mobileScreenshot: String?
    public let tabletScreenshot: String?
    public let themeSlug: String?
    public let group: [String]?
    public let segmentID: Int64?
    public let categories: [RemoteSiteDesignCategory]

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case demoURL = "demo_url"
        case screenshot = "preview"
        case mobileScreenshot = "preview_mobile"
        case tabletScreenshot = "preview_tablet"
        case themeSlug = "theme"
        case group
        case segmentID = "segment_id"
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        slug = try map.decode(String.self, forKey: .slug)
        title = try map.decode(String.self, forKey: .title)
        demoURL = try map.decode(String.self, forKey: .demoURL)
        screenshot = try? map.decode(String.self, forKey: .screenshot)
        mobileScreenshot = try? map.decode(String.self, forKey: .mobileScreenshot)
        tabletScreenshot = try? map.decode(String.self, forKey: .tabletScreenshot)
        themeSlug = try? map.decode(String.self, forKey: .themeSlug)
        group = try? map.decode([String].self, forKey: .group)
        segmentID = try? map.decode(Int64.self, forKey: .segmentID)
        categories = try map.decode([RemoteSiteDesignCategory].self, forKey: .categories)
    }
}

public struct RemoteSiteDesignCategory: Codable, Comparable {
    public static func < (lhs: RemoteSiteDesignCategory, rhs: RemoteSiteDesignCategory) -> Bool {
        return lhs.slug < rhs.slug
    }

    public let slug: String
    public let title: String
    public let description: String
    public let emoji: String?

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case description
        case emoji
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        slug = try map.decode(String.self, forKey: .slug)
        title = try map.decode(String.self, forKey: .title)
        description = try map.decode(String.self, forKey: .description)
        emoji = try? map.decode(String.self, forKey: .emoji)
    }
}
