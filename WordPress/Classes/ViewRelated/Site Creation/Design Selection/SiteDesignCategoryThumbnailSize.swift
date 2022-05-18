import Foundation

enum SiteDesignCategoryThumbnailSize {
    case category
    case recommended

    var value: CGSize {
        switch self {
        case .category where UIDevice.isPad():
            return .init(width: 250, height: 325)
        case .category:
            return .init(width: 200, height: 260)
        case .recommended where UIDevice.isPad():
            return .init(width: 327, height: 450)
        case .recommended:
            return .init(width: 350, height: 450)
        }
    }
}
