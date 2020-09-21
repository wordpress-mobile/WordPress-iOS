import WordPressKit

/// Generic feature announcement cache
protocol AnnouncementsCache {
    var announcements: [Announcement]? { get set }
}


/// UserDefaults-based cache for feature announcements
struct UserDefaultsAnnouncementsCache: AnnouncementsCache {

    var announcements: [Announcement]? {
        get {
            guard let announcements = UserDefaults.standard.announcements, versionIsValid(for: announcements) else {
                UserDefaults.standard.announcements = nil
                UserDefaults.standard.shouldHideAnnouncements = false
                return nil
            }
            return announcements
        }
        set {
            UserDefaults.standard.announcements = newValue
        }
    }

    private func versionIsValid(for announcements: [Announcement]) -> Bool {
        guard let minimumVersion = announcements.first?.minimumAppVersion, // there should not be more than one announcement
            let maximumVersion = announcements.first?.maximumAppVersion,   // per version, but if there is, each of them must match the version
            let targetVersions = announcements.first?.appVersionTargets,   // so we might as well choose the first
            let version = Bundle.main.shortVersionString(),
            ((minimumVersion...maximumVersion).contains(version) || targetVersions.contains(version)) else { // if version has changed, clean up the announcements cache
                return false
        }
        return true
    }
}


extension UserDefaults {

    static let currentAnnouncementsKey = "currentAnnouncements"
    static let shouldHideAnnouncementsKey = "shouldHideAnnouncementsKey"

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

    var shouldHideAnnouncements: Bool {
        get {
            // do not display announcements in a fresh install
            if object(forKey: UserDefaults.shouldHideAnnouncementsKey) == nil {
                set(true, forKey: UserDefaults.shouldHideAnnouncementsKey)
                return true
            }
            return bool(forKey: UserDefaults.shouldHideAnnouncementsKey)
        }
        set {
            set(newValue, forKey: UserDefaults.shouldHideAnnouncementsKey)
        }
    }
}
