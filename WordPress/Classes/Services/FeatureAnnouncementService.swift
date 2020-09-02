import Foundation
import WordPressKit

/// Provides feature announcements from the backend
class FeatureAnnouncementService {
    // TODO - WHATSNEW: this needs to be completed, for now it's basically a placeholder
    let remoteService: AnnouncementServiceRemote

    init(remoteService: AnnouncementServiceRemote) {
        self.remoteService = remoteService
    }
}
