import Foundation

///
protocol BlogDashboardPersonalizable {

    var blogDashboardPersonalizationKey: String? { get }

    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope { get }
}

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

    // MARK: - Core API

    func setEnabled(_ isEnabled: Bool, forKey key: String, scope: SettingsScope) {
        var settings = getSettings(for: key)
        let lookUpKey = lookUpKey(from: scope)
        settings[lookUpKey] = isEnabled
        self.repository.set(settings, forKey: key)
        NotificationCenter.default.post(name: .blogDashboardPersonalizationSettingsChanged, object: self)
    }

    func isEnabled(_ key: String, scope: SettingsScope) -> Bool {
        let settings = getSettings(for: key)
        let key = lookUpKey(from: scope)
        return settings[key, default: true]
    }

    func setEnabled(_ isEnabled: Bool, for item: BlogDashboardPersonalizable) {
        guard let key = item.blogDashboardPersonalizationKey else {
            return
        }
        self.setEnabled(
            isEnabled,
            forKey: key,
            scope: item.blogDashboardPersonalizationSettingsScope
        )
    }

    func isEnabled(_ item: BlogDashboardPersonalizable) -> Bool {
        guard let key = item.blogDashboardPersonalizationKey else {
            return true
        }
        return self.isEnabled(key, scope: item.blogDashboardPersonalizationSettingsScope)
    }

    private func lookUpKey(from scope: SettingsScope) -> String {
        switch scope {
        case .siteGeneric: return siteID
        case .siteSpecific: return Constants.siteAgnosticVisibilityKey
        }
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
        return self.isEnabled(card as BlogDashboardPersonalizable)
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
        self.setEnabled(isEnabled, for: card as BlogDashboardPersonalizable)
    }

    private func getSettings(for card: DashboardCard) -> [String: Bool] {
        guard let key = card.blogDashboardPersonalizationKey else {
            return [:]
        }
        return repository.dictionary(forKey: key) as? [String: Bool] ?? [:]
    }

    private func lookUpKey(for card: DashboardCard) -> String {
        return lookUpKey(from: card.blogDashboardPersonalizationSettingsScope)
    }

    // MARK: - Types

    enum SettingsScope {
        case siteSpecific
        case siteGeneric
    }
}

private func makeKey(for action: DashboardQuickAction) -> String {
    "quick-action-\(action.rawValue)-hidden"
}

extension NSNotification.Name {
    /// Sent whenever any of the blog settings managed by ``BlogDashboardPersonalizationService``
    /// are changed.
    static let blogDashboardPersonalizationSettingsChanged = NSNotification.Name("BlogDashboardPersonalizationSettingsChanged")
}
