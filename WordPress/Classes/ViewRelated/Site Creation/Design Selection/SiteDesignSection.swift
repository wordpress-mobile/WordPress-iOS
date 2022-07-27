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

    var sectionType: SiteDesignSectionType = .standard
}

extension SiteDesignSection {
    init(category: RemoteSiteDesignCategory,
         designs: [RemoteSiteDesign],
         thumbnailSize: CGSize,
         sectionType: SiteDesignSectionType = .standard) {

        self.designs = designs
        self.thumbnailSize = thumbnailSize
        self.categorySlug = category.slug
        self.title = category.title
        self.emoji = category.emoji
        self.description = category.description
        self.sectionType = sectionType
    }
}

extension SiteDesignSection: Equatable {
    static func == (lhs: SiteDesignSection, rhs: SiteDesignSection) -> Bool {
        lhs.categorySlug == rhs.categorySlug
    }
}

enum SiteDesignSectionType {
    case recommended
    case standard
}
