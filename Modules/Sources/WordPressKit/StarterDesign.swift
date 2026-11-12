import Foundation

/// An entry in WordPress.com's web starter design catalog (`wpcom/v2/starter-designs`).
public struct StarterDesign: Decodable, Equatable, Sendable {
    public struct Category: Decodable, Equatable, Sendable {
        public let slug: String
        public let name: String

        public init(slug: String, name: String) {
            self.slug = slug
            self.name = name
        }
    }

    public let slug: String
    public let title: String
    /// The theme stylesheet, for example `pub/formwork`.
    public let stylesheet: String
    public let categories: [Category]
    /// The theme tier slug, for example `free` or `premium`.
    public let themeTier: String?
    public let screenshot: String?
    /// A virtual design is a theme plus a pattern recipe, so activating its theme alone does not reproduce it.
    public let isVirtual: Bool

    /// The theme ID to activate, for example `formwork` for the `pub/formwork` stylesheet.
    public var themeID: String {
        stylesheet.split(separator: "/").last.map(String.init) ?? stylesheet
    }

    public init(
        slug: String,
        title: String,
        stylesheet: String,
        categories: [Category],
        themeTier: String?,
        screenshot: String?,
        isVirtual: Bool = false
    ) {
        self.slug = slug
        self.title = title
        self.stylesheet = stylesheet
        self.categories = categories
        self.themeTier = themeTier
        self.screenshot = screenshot
        self.isVirtual = isVirtual
    }

    private enum CodingKeys: String, CodingKey {
        case slug
        case title
        case recipe
        case categories
        case themeTier = "theme_tier"
        case screenshot
        case isVirtual = "is_virtual"
    }

    private enum RecipeKeys: String, CodingKey {
        case stylesheet
    }

    private enum ThemeTierKeys: String, CodingKey {
        case slug
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        title = try container.decode(String.self, forKey: .title)
        stylesheet = try container.nestedContainer(keyedBy: RecipeKeys.self, forKey: .recipe)
            .decode(String.self, forKey: .stylesheet)
        categories = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        themeTier = try? container.nestedContainer(keyedBy: ThemeTierKeys.self, forKey: .themeTier)
            .decode(String.self, forKey: .slug)
        screenshot = try container.decodeIfPresent(String.self, forKey: .screenshot)
        isVirtual = try container.decodeIfPresent(Bool.self, forKey: .isVirtual) ?? false
    }
}
