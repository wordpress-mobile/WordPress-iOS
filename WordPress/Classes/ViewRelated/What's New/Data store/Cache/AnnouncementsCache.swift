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
                UserDefaults.standard.announcements = nil
                return false
        }
        return true
    }
}


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
