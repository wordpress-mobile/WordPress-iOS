import Foundation
import UIKit
import WordPressUI

final class CompliancePopoverViewModel: ObservableObject {
    @Published
    var isAnalyticsEnabled: Bool = !WPAppAnalytics.userHasOptedOut()
    var coordinator: CompliancePopoverCoordinator?

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func didTapSettings() {
        coordinator?.navigateToSettings()
        defaults.didShowCompliancePopup = true
    }

    func didTapSave() {
        let appAnalytics = WordPressAppDelegate.shared?.analytics
        appAnalytics?.setUserHasOptedOut(!isAnalyticsEnabled)

        let (accountID, restAPI) = ContextManager.shared.performQuery { context -> (NSNumber?, WordPressComRestApi?) in
           let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
            return (account?.userID, account?.wordPressComRestApi)
        }

        guard let accountID, let restAPI else {
            return
        }

        let change = AccountSettingsChange.tracksOptOut(!isAnalyticsEnabled)
        AccountSettingsService(userID: accountID.intValue, api: restAPI).saveChange(change)
        coordinator?.dismiss()
        defaults.didShowCompliancePopup = true
    }
}
