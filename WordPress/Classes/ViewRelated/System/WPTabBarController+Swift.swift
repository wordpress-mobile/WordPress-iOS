
// MARK: - Tab Access Tracking

extension WPTabBarController {
    private static let tabIndexToStatMap: [WPTabType: WPAnalyticsStat] = [
        .mySites: .mySitesTabAccessed,
        .reader: .readerAccessed,
        .me: .meTabAccessed
    ]

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

        guard let tabType = WPTabType(rawValue: UInt(tabIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
                return false
        }

        WPAppAnalytics.track(stat)
        return true
    }

    /// Set up the tab bar's colors
    @objc func setupColors() {
        tabBar.unselectedItemTintColor = .unselected
        if !FeatureFlag.murielColors.enabled {
            tabBar.isTranslucent = false
        }
    }

//    @objc func setBadgeColor(for item: UITabBarItem) {
//        item.badgeColor = .accent
//    }
//
//    @objc func showReaderBadge(_ notification: NSNotification) {
//    }
//
//    @objc func  hideReaderBadge(_ notification: NSNotification) {
//        let readerIconName: String
//        if FeatureFlag.murielColors.enabled {
//            readerIconName = "icon-tab-reader-muriel"
//        } else {
//            readerIconName = "icon-tab-reader"
//        }
//        let readerTabBarImage = UIImage(named:readerIconName)
//        readerNavigationController.tabBarItem.image = readerTabBarImage
//    }

//    - (void) showReaderBadge:(NSNotification *)notification
//    {
//    UIImage *readerTabBarImage = [[UIImage imageNamed:@"icon-tab-reader-unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    self.readerNavigationController.tabBarItem.image = readerTabBarImage;
//    }
//
//    - (void) hideReaderBadge:(NSNotification *)notification
//    {
//    NSString *readerIconName = [Feature enabled:FeatureFlagMurielColors] ? @"icon-tab-reader" : @"icon-tab-reader-muriel";
//    UIImage *readerTabBarImage = [UIImage imageNamed:readerIconName];
//    self.readerNavigationController.tabBarItem.image = readerTabBarImage;
//    }
}
