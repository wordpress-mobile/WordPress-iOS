import Foundation

class SiteDesignSection: CategorySection {
    var category: RemoteSiteDesignCategory
    var designs: [RemoteSiteDesign]

    var categorySlug: String { category.slug }
    var title: String { category.title }
    var emoji: String? { category.emoji }
    var description: String? { category.description }
    var thumbnails: [Thumbnail] { designs }
    var scrollOffset: CGPoint

    init(category: RemoteSiteDesignCategory, designs: [RemoteSiteDesign]) {
        self.category = category
        self.designs = designs
        self.scrollOffset = .zero
    }
}
