import Foundation

/// A helper class for My Site that manages the default section to display
///
@objc final class MySiteSettings: NSObject {

    private let userDefaults: UserDefaults

    var defaultSection: MySiteViewController.Section {
        let defaultSection: MySiteViewController.Section = .siteMenu
        let rawValue = userDefaults.object(forKey: Constants.defaultSectionKey) as? Int ?? defaultSection.rawValue
        return MySiteViewController.Section(rawValue: rawValue) ?? defaultSection
    }

    @objc var experimentAssignment: String {
        let defaultSection: MySiteViewController.Section = .siteMenu
        let rawValue = userDefaults.object(forKey: Constants.defaultSectionKey) as? Int ?? defaultSection.rawValue
        return MySiteViewController.Section(rawValue: rawValue)?.analyticsDescription ?? "nonexistent"
    }

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setDefaultSection(_ tab: MySiteViewController.Section) {
        userDefaults.set(tab.rawValue, forKey: Constants.defaultSectionKey)
    }

    private enum Constants {
        static let defaultSectionKey = "MySiteDefaultSectionKey"
    }
}
