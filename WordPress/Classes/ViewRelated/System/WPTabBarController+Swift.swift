
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
    /// We want to call this when:
    ///
    /// - The app has been placed in the foreground
    /// - The app was just launched and we restored the previously selected tab
    ///   (in `decodeRestorableStateWithCoder`)
    /// - The user selected a different tab
    @objc func trackAccessStatForTabIndex(_ tabIndex: Int) {
        // Since this ViewController is a singleton, it can be active **behind** the login view.
        // The `isViewonScreen()` prevents us from tracking this.
        //
        // The `presentedViewController` check is to avoid tracking while a modal dialog is shown
        // and the app is placed in the background and back to foreground.
        guard isViewOnScreen(), presentedViewController == nil else {
            return
        }

        guard let tabType = WPTabType(rawValue: UInt(tabIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
                return
        }

        WPAppAnalytics.track(stat)
    }
}
