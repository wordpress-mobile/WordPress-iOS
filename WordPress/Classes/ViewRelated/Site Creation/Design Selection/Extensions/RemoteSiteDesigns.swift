import Foundation
import WordPressKit

extension RemoteSiteDesigns {
    func designsForCategory(_ category: RemoteSiteDesignCategory) -> [RemoteSiteDesign] {
       return designs.filter {
           $0.categories.map { $0.slug }.contains(category.slug)
       }
    }

    func randomizedDesignsForCategory(_ category: RemoteSiteDesignCategory) -> [RemoteSiteDesign] {
        return designsForCategory(category).shuffled()
    }
}
