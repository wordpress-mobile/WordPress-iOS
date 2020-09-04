
/// dependency container for the What's New / Feature Announcements scene
extension WPTabBarController {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: WhatIsNewStrings.version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource())
    }

    private func makeDataSource() -> AnnouncementsDataSource {
        return FeatureAnnouncementsDataSource(store: makeAnnouncementStore(),
                                              cellTypes: ["announcementCell": AnnouncementCell.self, "findOutMoreCell": FindOutMoreCell.self])
    }

    private func makeAnnouncementStore() -> AnnouncementsStore {
        return RemoteAnnouncementsStore()
    }

    private func makeApi() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: CoreDataManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }

    private enum WhatIsNewStrings {
        static let title = NSLocalizedString("What's New in WordPress", comment: "Title of the What's new page.")
        static let versionPrefix = NSLocalizedString("Version ", comment: "Description for the version label in the What's new page.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title for the continue button in the What's New page.")
        static var version: String {
            Bundle.main.shortVersionString() != nil ? versionPrefix + Bundle.main.shortVersionString() : ""
        }
    }
}
