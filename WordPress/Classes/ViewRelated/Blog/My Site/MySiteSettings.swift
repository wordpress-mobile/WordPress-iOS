import Foundation
import WordPressShared

protocol DefaultSectionProvider {
    var defaultSection: MySiteViewController.Section { get }
}

/// A helper class for My Site that manages the default section to display
///
@objc final class MySiteSettings: NSObject, DefaultSectionProvider {

    private var userDefaults: UserDefaults {
        UserDefaults.standard
    }

    var defaultSection: MySiteViewController.Section {
        let defaultSection: MySiteViewController.Section = .siteMenu
        let rawValue = userDefaults.object(forKey: Constants.defaultSectionKey) as? Int ?? defaultSection.rawValue
        return MySiteViewController.Section(rawValue: rawValue) ?? defaultSection
    }

    @objc var experimentAssignment: String {
        if let rawValue = userDefaults.object(forKey: Constants.defaultSectionKey) as? Int,
            let defaultSection = MySiteViewController.Section(rawValue: rawValue)?.analyticsDescription {
            return defaultSection
        }

        return "nonexistent"
    }

    @objc var isAssignedToExperiment: Bool {
        FeatureFlag.mySiteDashboard.enabled && experimentAssignment != "nonexistent"
    }

    func setDefaultSection(_ tab: MySiteViewController.Section) {
        userDefaults.set(tab.rawValue, forKey: Constants.defaultSectionKey)
        QuickStartTourGuide.shared.refreshQuickStart()
        WPAnalytics.track(.mySiteDefaultTabExperimentVariantAssigned, properties: ["default_tab_experiment": experimentAssignment])
    }

    private enum Constants {
        static let defaultSectionKey = "MySiteDefaultSectionKey"
    }
}
