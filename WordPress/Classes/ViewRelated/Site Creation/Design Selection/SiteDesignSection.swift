import Foundation

struct SiteDesignSection: CategorySection {
    var designs: [RemoteSiteDesign]
    var thumbnailSize: CGSize

    var caption: String?
    var categorySlug: String
    var title: String
    var emoji: String?
    var description: String?
    var thumbnails: [Thumbnail] { designs }
    var scrollOffset: CGPoint = .zero
}

extension SiteDesignSection {
    init(category: RemoteSiteDesignCategory, designs: [RemoteSiteDesign], thumbnailSize: CGSize, caption: String? = nil) {
        self.designs = designs
        self.thumbnailSize = thumbnailSize
        self.categorySlug = category.slug
        self.title = category.title
        self.emoji = category.emoji
        self.description = category.description
        self.caption = caption
    }
}

extension SiteDesignSection: Equatable {
    static func == (lhs: SiteDesignSection, rhs: SiteDesignSection) -> Bool {
        lhs.categorySlug == rhs.categorySlug
    }
}
