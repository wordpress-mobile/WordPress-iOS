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
            return UserDefaults.standard.announcements
        }
        set {
            UserDefaults.standard.announcements = newValue
        }
    }

    var date: Date? {
        UserDefaults.standard.announcementsDate
    }
}


// MARK: - Cache on disk
private extension UserDefaults {

    static let currentAnnouncementsKey = "currentAnnouncements"
    static let currentAnnouncementsDateKey = "currentAnnouncementsDate"

    var announcements: [Announcement]? {
        get {
            guard let encodedAnnouncements = value(forKey: Self.currentAnnouncementsKey) as? Data,
                  let announcements = try? PropertyListDecoder().decode([Announcement].self, from: encodedAnnouncements) else {
                return nil
            }
            return announcements
        }

        set {
            guard let announcements = newValue, let encodedAnnouncements = try? PropertyListEncoder().encode(announcements) else {
                removeObject(forKey: Self.currentAnnouncementsKey)
                removeObject(forKey: Self.currentAnnouncementsDateKey)
                return
            }
            set(encodedAnnouncements, forKey: Self.currentAnnouncementsKey)
            set(Date(), forKey: Self.currentAnnouncementsDateKey)
        }
    }

    var announcementsDate: Date? {
        value(forKey: Self.currentAnnouncementsDateKey) as? Date
    }
}
