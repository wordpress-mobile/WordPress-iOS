import Foundation

/// Manages dashboard settings such as card visibility.
struct BlogDashboardPersonalizationService {
    private let repository: UserPersistentRepository
    private let siteID: String

    init(repository: UserPersistentRepository = UserDefaults.standard,
         siteID: Int) {
        self.repository = repository
        self.siteID = String(siteID)
    }

    func isEnabled(_ card: DashboardCard) -> Bool {
        getSettings(for: card)[siteID] ?? true
    }

    func hasPreference(for card: DashboardCard) -> Bool {
        getSettings(for: card)[siteID] != nil
    }

    func setEnabled(_ isEnabled: Bool, for card: DashboardCard) {
        var settings = getSettings(for: card)
        settings[siteID] = isEnabled
        repository.set(settings, forKey: makeKey(for: card))

        NotificationCenter.default.post(name: .blogDashboardPersonalizationSettingsChanged, object: self)
    }

    private func getSettings(for card: DashboardCard) -> [String: Bool] {
        repository.dictionary(forKey: makeKey(for: card)) as? [String: Bool] ?? [:]
    }
}

private func makeKey(for card: DashboardCard) -> String {
    if card == .prompts {
        // This key was defined statically in the previous versions, and the
        // naming convention wasn't matching the other keys, so it had to be
        // special-cased to avoid losing data.
        return "prompts-enabled-site-settings"
    }
    return "\(card.rawValue)-card-enabled-site-settings"
}

extension NSNotification.Name {
    /// Sent whenever any of the blog settings managed by ``BlogDashboardPersonalizationService``
    /// are changed.
    static let blogDashboardPersonalizationSettingsChanged = NSNotification.Name("BlogDashboardPersonalizationSettingsChanged")
}
