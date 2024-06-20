public struct StatsTagsAndCategoriesInsight: Codable {
    public let topTagsAndCategories: [StatsTagAndCategory]

    private enum CodingKeys: String, CodingKey {
        case topTagsAndCategories = "tags"
    }
}

extension StatsTagsAndCategoriesInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/tags"
    }
}

public struct StatsTagAndCategory: Codable {
    public enum Kind: String, Codable {
        case tag
        case category
        case folder
    }

    public let name: String
    public let kind: Kind
    public let url: URL?
    public let viewsCount: Int?
    public let children: [StatsTagAndCategory]

    private enum CodingKeys: String, CodingKey {
        case name
        case kind = "type"
        case url = "link"
        case viewsCount = "views"
        case children = "tags"
    }

    public init(name: String, kind: Kind, url: URL?, viewsCount: Int?, children: [StatsTagAndCategory]) {
        self.name = name
        self.kind = kind
        self.url = url
        self.viewsCount = viewsCount
        self.children = children
    }
}

extension StatsTagAndCategory {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let innerTags = try container.decodeIfPresent([StatsTagAndCategory].self, forKey: .children) ?? []
        let viewsCount = (try? container.decodeIfPresent(Int.self, forKey: .viewsCount)) ?? 0

        // This gets kinda complicated. The API collects some tags/categories
        // into groups, and we have to handle that.
        if innerTags.isEmpty {
            self.init(
                name: try container.decode(String.self, forKey: .name),
                kind: try container.decode(Kind.self, forKey: .kind),
                url: try container.decodeIfPresent(URL.self, forKey: .url),
                viewsCount: nil,
                children: []
            )
        } else if innerTags.count == 1, let tag = innerTags.first {
            self.init(singleTag: tag, viewsCount: viewsCount)
        } else {
            let mappedChildren = innerTags.compactMap { StatsTagAndCategory(singleTag: $0) }
            let label = mappedChildren.map { $0.name }.joined(separator: ", ")
            self.init(name: label, kind: .folder, url: nil, viewsCount: viewsCount, children: mappedChildren)
        }
    }

    init(singleTag tag: StatsTagAndCategory, viewsCount: Int? = 0) {
        let kind: Kind

        switch tag.kind {
        case .category:
            kind = .category
        case .tag:
            kind = .tag
        default:
            kind = .category
        }

        self.init(name: tag.name, kind: kind, url: tag.url, viewsCount: viewsCount, children: [])
    }
}
