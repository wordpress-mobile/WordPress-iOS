import Foundation
import WordPressKit

extension RemotePostCategory {
    public static func remotePostCategoriesFromString(_ categories: String?) -> [RemotePostCategory]? {
        guard let categories, !categories.isEmpty else {
            return nil
        }

        let remotePostcategories: [RemotePostCategory] = categories.arrayOfTags().compactMap({Int($0)}).map({
            let remoteCat = RemotePostCategory()
            remoteCat.categoryID = NSNumber(value: $0)
            return remoteCat
        })
        return remotePostcategories
    }
}
