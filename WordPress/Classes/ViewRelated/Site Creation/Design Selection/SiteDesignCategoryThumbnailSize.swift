import UIKit

enum SiteDesignCategoryThumbnailSize {
    case category
    case recommended

    /// The size the design previews are requested at. It's the largest thumbnail size, so the previews are never
    /// scaled up when the window's size class changes after they load. Smaller thumbnails crop them to fill.
    static let previewSize = CGSize(width: 350, height: 450)

    /// - Parameter windowSizeClass: The horizontal size class of the window that displays the thumbnails.
    func value(for windowSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        switch self {
        case .category where windowSizeClass == .regular:
            return .init(width: 250, height: 325)
        case .category:
            return .init(width: 200, height: 260)
        case .recommended where windowSizeClass == .regular:
            return .init(width: 327, height: 450)
        case .recommended:
            return .init(width: 350, height: 450)
        }
    }
}
