
// MARK: - Tracking

extension WPTabBarController {
    private static let tabIndexToStatMap: [WPTabType: WPAnalyticsStat] = [
        .mySites: .mySitesTabAccessed,
        .reader: .readerAccessed,
        .me: .meTabAccessed
    ]

    @objc func startObserversForTracking() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackAccessStatForCurrentlySelectedTab),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc func trackAccessStatForCurrentlySelectedTab() {
        trackAccessStatForTabIndex(selectedIndex)
    }

    /// Count the current tab as "accessed" in analytics.
    ///
    /// We want to call this on:
    ///
    /// - The app has been placed in the foreground
    /// - The app was just launched and we restored the previously selected tab
    ///   (in `decodeRestorableStateWithCoder`)
    /// - The user selected a different tab
    @objc func trackAccessStatForTabIndex(_ tabIndex: Int) {
        guard let tabType = WPTabType(rawValue: UInt(tabIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
                return
        }

        WPAppAnalytics.track(stat)
    }
}
