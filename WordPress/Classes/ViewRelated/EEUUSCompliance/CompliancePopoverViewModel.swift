import Foundation
import UIKit
import WordPressUI

final class CompliancePopoverViewModel: ObservableObject {
    @Published
    var isAnalyticsEnabled: Bool = true
    var coordinator: CompliancePopoverCoordinator?

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func didTapSettings() {
        coordinator?.navigateToSettings()
        defaults.shouldShowCompliancePopup = true
    }

    func didTapSave() {
        let appAnalytics = WordPressAppDelegate.shared?.analytics
        appAnalytics?.setUserHasOptedOut(!isAnalyticsEnabled)

        let context = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
            return }

        let change = AccountSettingsChange.tracksOptOut(!isAnalyticsEnabled)
        AccountSettingsService(userID: account.userID.intValue, api: account.wordPressComRestApi).saveChange(change)
        coordinator?.dismiss()
        defaults.shouldShowCompliancePopup = true
    }
}
