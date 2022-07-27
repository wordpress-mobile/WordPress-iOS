
// MARK: - Tab Access Tracking

extension WPTabBarController {
    private static let tabIndexToStatMap: [WPTab: WPAnalyticsStat] = [.mySites: .mySitesTabAccessed, .reader: .readerAccessed]

    private struct AssociatedKeys {
        static var shouldTrackTabAccessOnViewDidAppear = 0
    }

    private var shouldTrackTabAccessOnViewDidAppear: Bool {
        get {
            let storedVal = objc_getAssociatedObject(self, &AssociatedKeys.shouldTrackTabAccessOnViewDidAppear)
            return storedVal as? Bool ?? false
        }
        set(value) {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.shouldTrackTabAccessOnViewDidAppear,
                                     value,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc func startObserversForTabAccessTracking() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(trackTabAccessOnAppDidBecomeActive),
                       name: UIApplication.didBecomeActiveNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(resetViewDidAppearFlagOnWPComAccountChange),
                       name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged,
                       object: nil)
    }

    @objc func trackTabAccessOnAppDidBecomeActive() {
        trackTabAccessForTabIndex(selectedIndex)
    }

    /// Reset `shouldTrackTabAccessOnViewDidAppear` if the user has logged out.
    ///
    /// This allows us to track tab access on `-viewDidAppear` when the user logs back in again.
    @objc func resetViewDidAppearFlagOnWPComAccountChange(_ notification: NSNotification) {
        guard notification.object == nil else {
            return
        }

        shouldTrackTabAccessOnViewDidAppear = true
    }

    /// Track tab access on viewDidAppear but only once.
    ///
    /// This covers the scenario when the user has just logged in.
    @objc func trackTabAccessOnViewDidAppear() {
        guard shouldTrackTabAccessOnViewDidAppear else {
            return
        }

        if trackTabAccessForTabIndex(selectedIndex) {
            shouldTrackTabAccessOnViewDidAppear = false
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
    @objc @discardableResult func trackTabAccessForTabIndex(_ tabIndex: Int) -> Bool {
        // Since this ViewController is a singleton, it can be active **behind** the login view.
        // The `isViewonScreen()` prevents us from tracking this. It also helps us in avoiding
        // tracking events if a modal dialog is shown and the app is placed in the background
        // and back to foreground.
        guard isViewOnScreen() else {
            return false
        }

        guard let tabType = WPTab(rawValue: Int(tabIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
                return false
        }

        WPAppAnalytics.track(stat)

        return true
    }

    /// Set up the tab bar's colors
    @objc func setupColors() {
        tabBar.isTranslucent = false
    }
}
