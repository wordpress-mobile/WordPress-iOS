import Foundation
import WordPressShared

protocol DefaultSectionProvider {
    var defaultSection: MySiteViewController.Section { get }
}

/// A helper class for My Site that manages the default section to display
///
@objc final class MySiteSettings: NSObject, DefaultSectionProvider {

    private var userDefaults: UserPersistentRepository {
        UserPersistentStoreFactory.instance()
    }

    var defaultSection: MySiteViewController.Section {
        let defaultSection: MySiteViewController.Section = AppConfiguration.isJetpack ? .dashboard : .siteMenu
        let rawValue = userDefaults.object(forKey: Constants.defaultSectionKey) as? Int ?? defaultSection.rawValue
        return MySiteViewController.Section(rawValue: rawValue) ?? defaultSection
    }

    func setDefaultSection(_ tab: MySiteViewController.Section) {
        userDefaults.set(tab.rawValue, forKey: Constants.defaultSectionKey)
        QuickStartTourGuide.shared.refreshQuickStart()
    }

    private enum Constants {
        static let defaultSectionKey = "MySiteDefaultSectionKey"
    }
}
