import Foundation
import WordPressKit

class BlogDashboardService {
    let remoteService: DashboardServiceRemote

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
    }
}
