import Foundation
import UIKit
import WordPressKit

struct SiteDesignSection: CategorySection {
    var designs: [RemoteSiteDesign]

    var caption: String?
    var categorySlug: String
    var title: String
    var emoji: String?
    var description: String?
    var thumbnails: [Thumbnail] { designs }

    var sectionType: SiteDesignSectionType = .standard

    /// The horizontal size class of the window that displays the section. Set it before display:
    /// `thumbnailSize` follows it.
    var windowSizeClass: UIUserInterfaceSizeClass = .unspecified

    var thumbnailSize: CGSize {
        let thumbnailSize: SiteDesignCategoryThumbnailSize = sectionType == .recommended ? .recommended : .category
        return thumbnailSize.value(for: windowSizeClass)
    }
}

extension SiteDesignSection {
    init(
        category: RemoteSiteDesignCategory,
        designs: [RemoteSiteDesign],
        sectionType: SiteDesignSectionType = .standard
    ) {

        self.designs = designs
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
