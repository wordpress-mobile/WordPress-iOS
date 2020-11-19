import WordPressKit

/// Generic feature announcement cache
protocol AnnouncementsCache {
    var announcements: [Announcement]? { get set }
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
}


// MARK: - Cache on disk
private extension UserDefaults {

    static let currentAnnouncementsKey = "currentAnnouncements"

    var announcements: [Announcement]? {
        get {
            guard let encodedAnnouncements = value(forKey: UserDefaults.currentAnnouncementsKey) as? Data,
                  let announcements = try? PropertyListDecoder().decode([Announcement].self, from: encodedAnnouncements) else {
                return nil
            }
            return announcements
        }

        set {
            guard let announcements = newValue, let encodedAnnouncements = try? PropertyListEncoder().encode(announcements) else {
                removeObject(forKey: UserDefaults.currentAnnouncementsKey)
                return
            }
            set(encodedAnnouncements, forKey: UserDefaults.currentAnnouncementsKey)
        }
    }
}
