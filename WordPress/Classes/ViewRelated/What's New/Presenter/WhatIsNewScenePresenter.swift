import WordPressFlux

class WhatIsNewScenePresenter: ScenePresenter {

    var presentedViewController: UIViewController?

    private var subscription: Receipt?

    private var startPresenting: (() -> Void)?

    private let store: AnnouncementsStore

    private func shouldPresentWhatIsNew(on viewController: UIViewController) -> Bool {
        viewController is AppSettingsViewController ||
            (AppRatingUtility.shared.didUpgradeVersion &&
                UserDefaults.standard.announcementsVersionDisplayed != Bundle.main.shortVersionString() &&
                self.store.announcements.first?.isLocalized == true)
    }

    var versionHasAnnouncements: Bool {
        store.versionHasAnnouncements
    }

    init(store: AnnouncementsStore) {
        self.store = store
        subscription = store.onChange { [weak self] in
            guard let self = self, !self.store.announcements.isEmpty else {
                return
            }
            self.startPresenting?()
        }
    }

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {

        defer {
            store.getAnnouncements()
        }

        startPresenting = { [weak viewController, weak self] in
            guard let self = self,
                let viewController = viewController,
                viewController.isViewOnScreen(),
                self.shouldPresentWhatIsNew(on: viewController) else {
                    return
                }
            let controller = self.makeWhatIsNewViewController()

            self.trackAccess(from: viewController)
            viewController.present(controller, animated: animated) {
                UserDefaults.standard.announcementsVersionDisplayed = Bundle.main.shortVersionString()
                completion?()
            }
        }
    }

    // analytics
    private func trackAccess(from viewController: UIViewController) {
        if viewController is AppSettingsViewController {
            WPAnalytics.track(.featureAnnouncementShown, properties: ["source": "app_settings"])
        } else {
            WPAnalytics.track(.featureAnnouncementShown, properties: ["source": "app_upgrade"])
        }
    }
}

// MARK: - Dependencies
private extension WhatIsNewScenePresenter {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView, onContinue: {
            WPAnalytics.track(.featureAnnouncementButtonTapped, properties: ["button": "close_dialog"])
        })
    }

    func makeWhatIsNewView() -> WhatIsNewView {

        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: WhatIsNewStrings.version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource())
    }

    func makeDataSource() -> AnnouncementsDataSource {
        return FeatureAnnouncementsDataSource(store: self.store,
                                              cellTypes: ["announcementCell": AnnouncementCell.self, "findOutMoreCell": FindOutMoreCell.self])
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


private extension UserDefaults {

    static let announcementsVersionDisplayedKey = "announcementsVersionDisplayed"

    var announcementsVersionDisplayed: String? {
        get {
            string(forKey: UserDefaults.announcementsVersionDisplayedKey)
        }
        set {
            set(newValue, forKey: UserDefaults.announcementsVersionDisplayedKey)
        }
    }
}
