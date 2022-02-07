import Foundation
import WordPressKit

class BlogDashboardService {
    let remoteService: DashboardServiceRemote

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
    }

    func fetch(wpComID: Int, completion: @escaping (DashboardSnapshot) -> Void) {
        let cardsToFetch: [String] = DashboardCard.allCases
            .filter { $0.isRemote }
            .map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: wpComID, success: { _ in
            completion(DashboardSnapshot())
        }, failure: { _ in

        })
    }
}
