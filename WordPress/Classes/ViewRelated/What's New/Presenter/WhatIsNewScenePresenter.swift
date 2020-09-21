
class WhatIsNewScenePresenter: ScenePresenter {

    var presentedViewController: UIViewController?

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let controller = makeWhatIsNewViewController()
        guard ((viewController is AppSettingsViewController) || !UserDefaults.standard.shouldHideAnnouncements),
            viewController.isViewOnScreen() else {
            return
        }

        viewController.present(controller, animated: true) { [weak viewController] in
            // if accessed via settings, do not influence the app update behavior
            guard !(viewController is AppSettingsViewController) else {
                return
            }
            UserDefaults.standard.shouldHideAnnouncements = true
        }
    }
}

// MARK: - Dependencies
private extension WhatIsNewScenePresenter {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: WhatIsNewStrings.version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource())
    }

    func makeDataSource() -> AnnouncementsDataSource {
        return FeatureAnnouncementsDataSource(store: makeAnnouncementStore(),
                                              cellTypes: ["announcementCell": AnnouncementCell.self, "findOutMoreCell": FindOutMoreCell.self])
    }

    func makeAnnouncementStore() -> AnnouncementsStore {
        return CachedAnnouncementsStore(cache: makeCache())
    }

    func makeCache() -> AnnouncementsCache {
        return UserDefaultsAnnouncementsCache()
    }

    func makeApi() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: CoreDataManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }

    enum WhatIsNewStrings {
        static let title = NSLocalizedString("What's New in WordPress", comment: "Title of the What's new page.")
        static let versionPrefix = NSLocalizedString("Version ", comment: "Description for the version label in the What's new page.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title for the continue button in the What's New page.")
        static var version: String {
            Bundle.main.shortVersionString() != nil ? versionPrefix + Bundle.main.shortVersionString() : ""
        }
    }
}


extension WPTabBarController {

    private func makeWhatIsNewPresenter() -> ScenePresenter {
        return WhatIsNewScenePresenter()
    }

    @objc func presentWhatIsNew(on viewController: UIViewController) {

        DispatchQueue.main.async { [weak viewController] in
            guard let viewController = viewController else {
                return
            }
            let presenter = self.makeWhatIsNewPresenter()
            presenter.present(on: viewController, animated: true, completion: nil)
        }
    }
}
