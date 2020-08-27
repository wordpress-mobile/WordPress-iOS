import Foundation
import WordPressKit

/// Provides feature announcements from the backend
class FeatureAnnouncementService {

    let remoteService: AnnouncementServiceRemote

    

    init(remoteService: AnnouncementServiceRemote) {
        self.remoteService = remoteService
    }
}
