
/// dependency container for the What's New / Feature Announcements scene
extension WPTabBarController {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        let version = Bundle.main.shortVersionString() != nil ?
            WhatIsNewStrings.versionPrefix + Bundle.main.shortVersionString() : ""

        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource())
    }

    private func makeDataSource() -> AnnouncementsDataSource {
        return FeatureAnnouncementsDataSource(features: [],
                                              cellTypes: ["announcementCell": AnnouncementCell.self, "findOutMoreCell": FindOutMoreCell.self],
                                              findOutMoreLink: WhatIsNewStrings.temporaryAnnouncementsLink)
    }

    private func makeFeatureAnnouncementService() -> FeatureAnnouncementService {
        return FeatureAnnouncementService(remoteService: makeAnnouncementServiceRemote())
    }

    private func makeAnnouncementServiceRemote() -> AnnouncementServiceRemote {
        return AnnouncementServiceRemote(wordPressComRestApi: makeApi())
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

        // TODO - WHATSNEW: to be removed when the real data come in
        static let temporaryAnnouncementsLink = "https://wordpress.com/"
    }
}
