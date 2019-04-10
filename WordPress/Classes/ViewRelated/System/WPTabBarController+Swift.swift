
// MARK: - Tab Access Tracking

extension WPTabBarController {
    private static let tabIndexToStatMap: [WPTabType: WPAnalyticsStat] = [
        .mySites: .mySitesTabAccessed,
        .reader: .readerAccessed,
        .me: .meTabAccessed
    ]

    private static var hasTrackedTabAccessOnViewDidAppearAssociatedKey = 0

    private var hasTrackedTabAccessOnViewDidAppear: Bool {
        get {
            return objc_getAssociatedObject(self, &WPTabBarController.hasTrackedTabAccessOnViewDidAppearAssociatedKey) as? Bool ?? false
        }
        set(value) {
            objc_setAssociatedObject(self, &WPTabBarController.hasTrackedTabAccessOnViewDidAppearAssociatedKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc func startObserversForTabAccessStatTracking() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(trackAccessStatForCurrentlySelectedTabOnEnterForeground),
                       name: UIApplication.willEnterForegroundNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(resetViewDidAppearTrackingFlagAfterWPComAccountChange(_:)),
                       name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged,
                       object: nil)
    }

    @objc func trackAccessStatForCurrentlySelectedTabOnEnterForeground() {
        trackAccessStatForTabIndex(selectedIndex)
    }

    /// Reset `hasTrackedTabAccessOnViewDidAppear` if the user has logged out.
    ///
    /// This allows us to track tab access on `-viewDidLoad` when the user logs back in again.
    @objc func resetViewDidAppearTrackingFlagAfterWPComAccountChange(_ notification: NSNotification) {
        guard notification.object == nil else {
            return
        }

        hasTrackedTabAccessOnViewDidAppear = false
    }

    /// Track tab access on viewDidAppear but only once.
    ///
    /// This covers events like:
    ///
    /// - The user logging in
    /// - The app was launched and we restored the previous tab on `decodeRestorableStateWithCoder`
    ///
    /// And this prevents incorrect tracking for scenarios like:
    ///
    /// - This VC is active on app launch but we're also showing the login VC. By calling this
    ///   method in `-viewDidLoad`, we are able to determine if the login VC is visible.
    /// - The user opens a webview and dismisses it. The `-viewDidLoad` gets called again.
    @objc func trackAccessStatForCurrentlySelectedTabOnViewDidAppear() {
        guard !hasTrackedTabAccessOnViewDidAppear else {
            return
        }

        if trackAccessStatForTabIndex(selectedIndex) {
            hasTrackedTabAccessOnViewDidAppear = true
        }
    }

    /// Count the current tab as "accessed" in analytics.
    ///
    /// We want to call this when the user is logged in and:
    ///
    /// - The app has been placed in the foreground
    /// - The app was just launched and we restored the previously selected tab
    ///   (in `decodeRestorableStateWithCoder`)
    /// - The user selected a different tab
    /// - After logging in (and this VC is shown)
    @objc @discardableResult func trackAccessStatForTabIndex(_ tabIndex: Int) -> Bool {
        // Since this ViewController is a singleton, it can be active **behind** the login view.
        // The `isViewonScreen()` prevents us from tracking this.
        //
        // The `presentedViewController` check is to avoid tracking while a modal dialog is shown
        // and the app is placed in the background and back to foreground.
        guard isViewOnScreen(), presentedViewController == nil else {
            return false
        }

        guard let tabType = WPTabType(rawValue: UInt(tabIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
                return false
        }

        WPAppAnalytics.track(stat)
        return true
    }
}
