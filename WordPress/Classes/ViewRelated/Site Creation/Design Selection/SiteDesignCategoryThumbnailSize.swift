import Foundation

enum SiteDesignCategoryThumbnailSize {
    case category
    case recommended

    var value: CGSize {
        if UIDevice.isPad() {
            return .init(width: 250, height: 325)
        }

        return .init(width: 200, height: 260)
    }
}
