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

    private var features: [WordPressKit.Feature] {
        store.announcements.reduce(into: [WordPressKit.Feature](), {
            $0.append(contentsOf: $1.features)
        })
    }

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView, onContinue: {
            WPAnalytics.track(.featureAnnouncementButtonTapped, properties: ["button": "close_dialog"])
        })
    }

    func makeWhatIsNewView() -> WhatIsNewView {
        if shouldUseDashboardCustomView() {
            return makeCustomWhatIsNewView()
        }
        else {
            return makeStandardWhatIsNewView()
        }
    }

    func makeDataSource() -> AnnouncementsDataSource {
        if shouldUseDashboardCustomView() {
            return makeCustomDataSource()
        }
        else {
            return makeStandardDataSource()
        }
    }

    private func makeStandardWhatIsNewView() -> WhatIsNewView {
        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: WhatIsNewStrings.version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle,
                                             disclaimerTitle: "")

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource(), appearance: .standard)
    }

    private func makeStandardDataSource() -> AnnouncementsDataSource {
        let detailsUrl = self.store.announcements.first?.detailsUrl ?? ""
        return FeatureAnnouncementsDataSource(features: features, detailsUrl: detailsUrl, announcementCellType: AnnouncementCell.self)
    }


    /// Creates a WhatIsNewView using custom layout for dashboard announcement
    /// Treats feature titles and subtitles of value "." as empty strings.
    private func makeCustomWhatIsNewView() -> WhatIsNewView {
        let title = features.first(where: {!$0.title.isFeatureStringEmpty()})?.title ?? WhatIsNewStrings.title // Extract title from features
        let viewTitles = WhatIsNewViewTitles(header: title,
                                             version: "",
                                             continueButtonTitle: WhatIsNewStrings.gotItButtonTitle,
                                             disclaimerTitle: WhatIsNewStrings.disclaimerTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource(), appearance: .dashboardCustom)
    }

    private func makeCustomDataSource() -> AnnouncementsDataSource {
        let adjustedFeatures = features.filter {$0.title.isFeatureStringEmpty() && !$0.subtitle.isFeatureStringEmpty()}
        let detailsUrl = self.store.announcements.first?.detailsUrl ?? ""
        return FeatureAnnouncementsDataSource(features: adjustedFeatures, detailsUrl: detailsUrl, announcementCellType: DashboardCustomAnnouncementCell.self)
    }

    private func shouldUseDashboardCustomView() -> Bool {
        return self.store.appVersionName == "23.3"
    }

    enum WhatIsNewStrings {
        static let title = AppConstants.Settings.whatIsNewTitle
        static let versionPrefix = NSLocalizedString("Version ", comment: "Description for the version label in the What's new page.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title for the continue button in the What's New page.")
        static let gotItButtonTitle = NSLocalizedString("Got it", comment: "Title for the continue button in the dashboard's custom What's New page.")
        static var version: String {
            Bundle.main.shortVersionString() != nil ? versionPrefix + Bundle.main.shortVersionString() : ""
        }
        static let disclaimerTitle = NSLocalizedString("NEW!", comment: "Title for disclaimer in the dashboard's custom What's New page.")
    }
}


private extension UserDefaults {
}

fileprivate extension String {
    func isFeatureStringEmpty() -> Bool {
        return self.isEmpty || self == "."
    }
}
