import Foundation

public struct RemotePageLayouts: Codable {
    public let layouts: [RemoteLayout]
    public let categories: [RemoteLayoutCategory]

    enum CodingKeys: String, CodingKey {
        case layouts
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        layouts = try map.decode([RemoteLayout].self, forKey: .layouts)
        categories = try map.decode([RemoteLayoutCategory].self, forKey: .categories)
    }

    public init() {
        self.init(layouts: [], categories: [])
    }

    public init(layouts: [RemoteLayout], categories: [RemoteLayoutCategory]) {
        self.layouts = layouts
        self.categories = categories
    }
}

public struct RemoteLayout: Codable {
    public let slug: String
    public let title: String
    public let preview: String?
    public let previewTablet: String?
    public let previewMobile: String?
    public let demoUrl: String?
    public let content: String?
    public let categories: [RemoteLayoutCategory]

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case preview
        case previewTablet = "preview_tablet"
        case previewMobile = "preview_mobile"
        case demoUrl = "demo_url"
        case content
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        slug = try map.decode(String.self, forKey: .slug)
        title = try map.decode(String.self, forKey: .title)
        preview = try? map.decode(String.self, forKey: .preview)
        previewTablet = try? map.decode(String.self, forKey: .previewTablet)
        previewMobile = try? map.decode(String.self, forKey: .previewMobile)
        demoUrl = try? map.decode(String.self, forKey: .demoUrl)
        content = try? map.decode(String.self, forKey: .content)
        categories = try map.decode([RemoteLayoutCategory].self, forKey: .categories)
    }
}

public struct RemoteLayoutCategory: Codable, Comparable {
    public static func < (lhs: RemoteLayoutCategory, rhs: RemoteLayoutCategory) -> Bool {
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
