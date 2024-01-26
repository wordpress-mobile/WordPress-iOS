import WordPressKit

/// Generic feature announcement cache
protocol AnnouncementsCache {
    var announcements: [Announcement]? { get set }
    var date: Date? { get }
}

/// UserDefaults-based cache for feature announcements
struct UserDefaultsAnnouncementsCache: AnnouncementsCache {

    var announcements: [Announcement]? {
        get {
            return UserPersistentStoreFactory.instance().announcements
        }
        set {
            UserPersistentStoreFactory.instance().announcements = newValue
        }
    }

    var date: Date? {
        UserPersistentStoreFactory.instance().announcementsDate
    }
}
