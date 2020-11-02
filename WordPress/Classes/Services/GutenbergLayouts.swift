import Foundation

public struct GutenbergPageLayouts: Codable {
    public let layouts: [GutenbergLayout]
    public let categories: [GutenbergLayoutCategory]

    enum CodingKeys: String, CodingKey {
        case layouts
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        layouts = try map.decode([GutenbergLayout].self, forKey: .layouts)
        categories = try map.decode([GutenbergLayoutCategory].self, forKey: .categories).sorted()
    }

    public init() {
        self.init(layouts: [], categories: [])
    }

    public init(layouts: [GutenbergLayout], categories: [GutenbergLayoutCategory]) {
        self.layouts = layouts
        self.categories = categories
    }
}

public struct GutenbergLayout: Codable {
    public let slug: String
    public let title: String
    public let preview: String?
    public let content: String?
    public let categories: [GutenbergLayoutCategory]

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case preview
        case content
        case categories
    }

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        slug = try map.decode(String.self, forKey: .slug)
        title = try map.decode(String.self, forKey: .title)
        preview = try? map.decode(String.self, forKey: .preview)
        content = try? map.decode(String.self, forKey: .content)
        categories = try map.decode([GutenbergLayoutCategory].self, forKey: .categories)
    }
}

public struct GutenbergLayoutCategory: Codable, Comparable {
    public static func < (lhs: GutenbergLayoutCategory, rhs: GutenbergLayoutCategory) -> Bool {
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
