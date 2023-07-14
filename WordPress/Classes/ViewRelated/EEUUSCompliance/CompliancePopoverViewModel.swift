import Foundation
import UIKit
import WordPressUI

class CompliancePopoverViewModel: ObservableObject {

    @Published
    var isAnalyticsEnabled: Bool = !WPAppAnalytics.userHasOptedOut()

    // MARK: - Dependencies

    var coordinator: CompliancePopoverCoordinatorProtocol?

    private let analyticsTracker: PrivacySettingsAnalyticsTracking
    private let defaults: UserDefaults
    private let contextManager: ContextManager

    // MARK: - Init

    init(defaults: UserDefaults,
         contextManager: ContextManager,
         analyticsTracker: PrivacySettingsAnalyticsTracking = PrivacySettingsAnalyticsTracker()) {
        self.defaults = defaults
        self.analyticsTracker = analyticsTracker
        self.contextManager = contextManager
    }

    // MARK: - API

    func didDisplayPopover() {
        analyticsTracker.track(.privacyChoicesBannerPresented)
    }

    func didTapSettings() {
        coordinator?.navigateToSettings()
        defaults.didShowCompliancePopup = true
        analyticsTracker.track(.privacyChoicesBannerSettingsButtonTapped)
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
        analyticsTracker.trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: isAnalyticsEnabled)
    }
}
