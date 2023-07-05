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
        defaults.shouldShowCompliancePopup = false
    }

    func didTapSave() {
        let appAnalytics = WordPressAppDelegate.shared?.analytics
        appAnalytics?.setUserHasOptedOut(!isAnalyticsEnabled)

        let account = ContextManager.shared.performQuery { context -> WPAccount? in
           let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
           return account
        }

        guard let account else {
            return
        }

        let change = AccountSettingsChange.tracksOptOut(!isAnalyticsEnabled)
        AccountSettingsService(userID: account.userID.intValue, api: account.wordPressComRestApi).saveChange(change)
        coordinator?.dismiss()
        defaults.shouldShowCompliancePopup = false
    }
}
