import Foundation

/// Manages dashboard settings such as card visibility.
struct BlogDashboardPersonalizationService {
    private enum Constants {
        static let siteAgnosticVisibilityKey = "siteAgnosticVisibilityKey"
    }

    private let repository: UserPersistentRepository
    private let siteID: String

    init(repository: UserPersistentRepository = UserDefaults.standard,
         siteID: Int) {
        self.repository = repository
        self.siteID = String(siteID)
    }

    // MARK: - Quick Actions

    func isEnabled(_ action: DashboardQuickAction) -> Bool {
        let settings = getSettings(for: makeKey(for: action))
        return settings[siteID] ?? action.isEnabledByDefault
    }

    func setEnabled(_ isEnabled: Bool, for action: DashboardQuickAction) {
        let key = makeKey(for: action)
        var settings = getSettings(for: key)
        settings[siteID] = isEnabled
        repository.set(settings, forKey: key)

        NotificationCenter.default.post(name: .blogDashboardPersonalizationSettingsChanged, object: self)
    }

    // Returns a `siteID` to a boolean mapping.
    private func getSettings(for key: String) -> [String: Bool] {
        repository.dictionary(forKey: key) as? [String: Bool] ?? [:]
    }

    // MARK: - Dashboard Cards

    func isEnabled(_ card: DashboardCard) -> Bool {
        let key = lookUpKey(for: card)
        return getSettings(for: card)[key] ?? true
    }

    func hasPreference(for card: DashboardCard) -> Bool {
        let key = lookUpKey(for: card)
        return getSettings(for: card)[key] != nil
    }

    /// Sets the enabled state for a given DashboardCard.
    ///
    /// This function updates the enabled state of a `DashboardCard`. `DashboardCard.settingsType`,
    /// the enabled state can be either site-specific or site-agnostic.
    /// After updating the settings, a notification is posted to inform other parts of the application about this change.
    /// - Parameters:
    ///   - isEnabled: A Boolean value indicating whether the `DashboardCard` should be enabled or disabled.
    ///   - card: The `DashboardCard` whose setting needs to be updated.
    func setEnabled(_ isEnabled: Bool, for card: DashboardCard) {
        guard let key = makeKey(for: card) else { return }
        var settings = getSettings(for: card)
        let lookUpKey = lookUpKey(for: card)
        settings[lookUpKey] = isEnabled

        repository.set(settings, forKey: key)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .blogDashboardPersonalizationSettingsChanged, object: self)
        }
    }

    private func getSettings(for card: DashboardCard) -> [String: Bool] {
        guard let key = makeKey(for: card) else { return [:] }
        return repository.dictionary(forKey: key) as? [String: Bool] ?? [:]
    }

    private func lookUpKey(for card: DashboardCard) -> String {
        switch card.settingsType {
        case .siteSpecific:
            return siteID
        case .siteGeneric:
            return Constants.siteAgnosticVisibilityKey
        }
    }
}

private func makeKey(for action: DashboardQuickAction) -> String {
    "quick-action-\(action.rawValue)-hidden"
}

private func makeKey(for card: DashboardCard) -> String? {
    switch card {
    case .todaysStats:
        return "todays-stats-card-enabled-site-settings"
    case .draftPosts:
        return "draft-posts-card-enabled-site-settings"
    case .scheduledPosts:
        return "scheduled-posts-card-enabled-site-settings"
    case .blaze:
        return "blaze-card-enabled-site-settings"
    case .prompts:
        // Warning: there is an irregularity with the prompts key that doesn't
        // have a "-card" component in the key name. Keeping it like this to
        // avoid having to migrate data.
        return "prompts-enabled-site-settings"
    case .freeToPaidPlansDashboardCard:
        return "free-to-paid-plans-dashboard-card-enabled-site-settings"
    case .domainRegistration:
        return "register-domain-dashboard-card"
    case .googleDomains:
        return "google-domains-card-enabled-site-settings"
    case .activityLog:
        return "activity-log-card-enabled-site-settings"
    case .pages:
        return "pages-card-enabled-site-settings"
    case .quickStart:
        return "quick-start-card-enabled-site-settings"
    case .jetpackBadge, .jetpackInstall, .jetpackSocial, .failure, .ghost, .personalize, .empty:
        return nil
    }
}

extension NSNotification.Name {
    /// Sent whenever any of the blog settings managed by ``BlogDashboardPersonalizationService``
    /// are changed.
    static let blogDashboardPersonalizationSettingsChanged = NSNotification.Name("BlogDashboardPersonalizationSettingsChanged")
}
