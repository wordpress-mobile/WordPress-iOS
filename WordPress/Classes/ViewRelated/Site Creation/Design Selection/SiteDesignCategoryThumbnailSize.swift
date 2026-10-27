import UIKit

enum SiteDesignCategoryThumbnailSize {
    case category
    case recommended

    /// - Parameter traitCollection: The trait collection of the view that displays the thumbnails.
    func value(for traitCollection: UITraitCollection) -> CGSize {
        switch self {
        case .category where traitCollection.horizontalSizeClass == .regular:
            return .init(width: 250, height: 325)
        case .category:
            return .init(width: 200, height: 260)
        case .recommended where traitCollection.horizontalSizeClass == .regular:
            return .init(width: 327, height: 450)
        case .recommended:
            return .init(width: 350, height: 450)
        }
    }
}
