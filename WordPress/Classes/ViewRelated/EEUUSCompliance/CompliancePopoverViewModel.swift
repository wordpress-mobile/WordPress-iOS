import Foundation
import UIKit
import WordPressUI

final class CompliancePopoverViewModel: ObservableObject {
    @Published
    var isAnalyticsEnabled: Bool = !WPAppAnalytics.userHasOptedOut()
    var coordinator: CompliancePopoverCoordinatorProtocol?

    private let defaults: UserDefaults
    private let contextManager: ContextManager

    init(defaults: UserDefaults, contextManager: ContextManager) {
        self.defaults = defaults
        self.contextManager = contextManager
    }

    func didTapSettings() {
        coordinator?.navigateToSettings()
        defaults.didShowCompliancePopup = true
    }

    func didTapSave() {
        let appAnalytics = WordPressAppDelegate.shared?.analytics
        appAnalytics?.setUserHasOptedOut(!isAnalyticsEnabled)

        let (accountID, restAPI) = contextManager.performQuery { context -> (NSNumber?, WordPressComRestApi?) in
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
