import Foundation
import CocoaLumberjack
import Reachability
import UIDeviceIdentifier
import WordPressAuthenticator
import AutomatticTracks
import WordPressComStatsiOS
import WordPressShared


// MARK: - Utility Configuration

extension WordPressAppDelegate {

    @objc class var shared: WordPressAppDelegate? {
        return UIApplication.shared.delegate as? WordPressAppDelegate
    }

    @objc func configureAnalytics() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        analytics = WPAppAnalytics(accountService: accountService,
                                   lastVisibleScreenBlock: { [weak self] in
            return self?.currentlySelectedScreen
        })
    }

    @objc func configureAppRatingUtility() {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return
        }

        let utility = AppRatingUtility.shared
        utility.register(section: "notifications", significantEventCount: 5)
        utility.systemWideSignificantEventCountRequiredForPrompt = 10
        utility.setVersion(version)
        utility.checkIfAppReviewPromptsHaveBeenDisabled(success: nil, failure: {
            DDLogError("Was unable to retrieve data about throttling")
        })
    }

    @objc func configureCrashlytics() {
        #if DEBUG
            return
        #else
            if let apiKey = ApiCredentials.crashlyticsApiKey() {
                crashlytics = WPCrashlytics(apiKey: apiKey)
            }
        #endif
    }

    @objc func configureHockeySDK() {
        hockey = HockeyManager()
        hockey.configure()
    }

    @objc func configureReachability() {
        internetReachability = Reachability.forInternetConnection()

        let reachabilityBlock: NetworkReachable = { [weak self] reachability in
            guard let reachability = reachability else {
                return
            }

            let wifi = reachability.isReachableViaWiFi() ? "Y" : "N"
            let wwan = reachability.isReachableViaWWAN() ? "Y" : "N"

            DDLogInfo("Reachability - Internet - WiFi: \(wifi) WWAN: \(wwan)")
            let newValue = reachability.isReachable()
            self?.connectionAvailable = newValue

            NotificationCenter.default.post(name: .reachabilityChanged, object: self, userInfo: [Foundation.Notification.reachabilityKey: newValue])
        }

        internetReachability.reachableBlock = reachabilityBlock
        internetReachability.unreachableBlock = reachabilityBlock

        internetReachability.startNotifier()

        connectionAvailable = internetReachability.isReachable()
    }

    @objc func configureSelfHostedChallengeHandler() {
        /// Note:
        /// WordPressKit, now imported via CocoaPods, has the `AppExtension Safe API Only` flag set to *true*. Meaning that
        /// the host app is, effectively as of now, responsible for presenting any alert onscreen (whenever a HTTP Challenge is
        /// received). Capicci?
        ///
        WordPressOrgXMLRPCApi.onChallenge = { (challenge, completionHandler) in
            guard let alertController = HTTPAuthenticationAlertController.controller(for: challenge, handler: completionHandler) else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            alertController.presentFromRootViewController()
        }
    }

    @objc func configureWordPressAuthenticator() {
        authManager = WordPressAuthenticationManager()

        authManager.initializeWordPressAuthenticator()
        authManager.startRelayingSupportNotifications()

        WordPressAuthenticator.shared.delegate = authManager
    }

    @objc func handleWebActivity(_ activity: NSUserActivity) {
        guard AccountHelper.isLoggedIn,
            activity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = activity.webpageURL else {
                FailureNavigationAction().failAndBounce(activity.webpageURL)
                return
        }

        UniversalLinkRouter.shared.handle(url: url)
    }
}

// MARK: - UIAppearance

extension WordPressAppDelegate {

    /// Sets up all of the shared component(s) Appearance.
    ///
    @objc func setupComponentsAppearance() {
        setupFancyAlertAppearance()
        setupFancyButtonAppearance()
    }


    /// Setup: FancyAlertView's Appearance
    ///
    private func setupFancyAlertAppearance() {
        let appearance = FancyAlertView.appearance()

        appearance.titleTextColor = WPStyleGuide.darkGrey()
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)

        appearance.bodyTextColor = WPStyleGuide.darkGrey()
        appearance.bodyFont = WPStyleGuide.fontForTextStyle(.body)

        appearance.actionFont = WPStyleGuide.fontForTextStyle(.headline)
        appearance.infoFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        appearance.infoTintColor = WPStyleGuide.wordPressBlue()

        appearance.topDividerColor = WPStyleGuide.greyLighten30()
        appearance.bottomDividerColor = WPStyleGuide.lightGrey()
        appearance.headerBackgroundColor = WPStyleGuide.lightGrey()
    }

    /// Setup: FancyButton's Appearance
    ///
    private func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.headline)
    }
}


// MARK: - Helpers

extension WordPressAppDelegate {

    @objc var currentlySelectedScreen: String {
        // Check if the post editor or login view is up
        let rootViewController = window.rootViewController
        if let presentedViewController = rootViewController?.presentedViewController {
            if presentedViewController is EditPostViewController {
                return "Post Editor"
            } else if presentedViewController is LoginNavigationController {
                return "Login View"
            }
        }

        return WPTabBarController.sharedInstance().currentlySelectedScreen()
    }

    @objc var isWelcomeScreenVisible: Bool {
        get {
            guard let presentedViewController = window.rootViewController?.presentedViewController as? UINavigationController else {
                return false
            }

            guard let visibleViewController = presentedViewController.visibleViewController else {
                return false
            }

            return WordPressAuthenticator.isAuthenticationViewController(visibleViewController)
        }
    }


    @objc(showWelcomeScreenIfNeededAnimated:)
    func showWelcomeScreenIfNeeded(animated: Bool) {
        guard isWelcomeScreenVisible == false && AccountHelper.isLoggedIn == false else {
            return
        }

        // Check if the presentedVC is UIAlertController because in iPad we show a Sign-out button in UIActionSheet
        // and it's not dismissed before the check and `dismissViewControllerAnimated` does not work for it
        if let presenter = window.rootViewController?.presentedViewController,
            !(presenter is UIAlertController) {
            presenter.dismiss(animated: animated, completion: { [weak self] in
                self?.showWelcomeScreen(animated, thenEditor: false)
            })
        } else {
            showWelcomeScreen(animated, thenEditor: false)
        }
    }

    @objc func showWelcomeScreen(_ animated: Bool, thenEditor: Bool) {
        if let rootViewController = window.rootViewController {
            WordPressAuthenticator.showLogin(from: rootViewController, animated: animated)
        }
    }

    @objc func trackLogoutIfNeeded() {
        if AccountHelper.isLoggedIn == false {
            WPAnalytics.track(.logout)
        }
    }
}

// MARK: - Keychain

extension WordPressAppDelegate {
    @objc class func fixKeychainAccess() {
        let query: [String: Any] = [String(kSecClass): kSecClassGenericPassword,
                                    String(kSecAttrAccessible): kSecAttrAccessibleWhenUnlocked,
                                    String(kSecReturnAttributes): true,
                                    String(kSecMatchLimit): kSecMatchLimitAll]
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }

        guard status == errSecSuccess,
            let resultArray = result as? [[String: Any]] else {
            return
        }

        DDLogVerbose("Fixing keychain items with wrong access requirements")

        for itemDict in resultArray {
            let query: [String: Any] = [SecAttributes.secClass: SecAttributes.genericPassword,
                                        SecAttributes.accessible: SecAttributes.whenUnlocked,
                                        SecAttributes.service: itemDict[SecAttributes.service] ?? NSNull(),
                                        SecAttributes.account: itemDict[SecAttributes.account] ?? NSNull(),
                                        SecAttributes.returnAttributes: true,
                                        SecAttributes.returnData: true]

            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, $0)
            }

            if status == errSecSuccess,
                let itemDict = result as? [String: Any] {

                let query: [String: Any] = [SecAttributes.secClass: SecAttributes.genericPassword,
                                            SecAttributes.accessible: SecAttributes.whenUnlocked,
                                            SecAttributes.service: itemDict[SecAttributes.service] ?? NSNull(),
                                            SecAttributes.account: itemDict[SecAttributes.account] ?? NSNull()]

                let updatedAttributes: [String: Any] = [SecAttributes.valueData: itemDict[SecAttributes.valueData] ?? NSNull(),
                                                        SecAttributes.accessible: SecAttributes.afterFirstUnlock]
                let status = SecItemUpdate(query as CFDictionary, updatedAttributes as CFDictionary)
                if status == errSecSuccess {
                    DDLogInfo("Migrated keychain item \(itemDict)")
                } else {
                    DDLogError("Error migrating keychain item: \(status)")
                }
            } else {
                DDLogError("Error migrating keychain item: \(status)")
            }
        }

        DDLogVerbose("End keychain fixing")
    }

    private enum SecAttributes {
        static let secClass = String(kSecClass)
        static let genericPassword = String(kSecClassGenericPassword)
        static let accessible = String(kSecAttrAccessible)
        static let whenUnlocked = String(kSecAttrAccessibleWhenUnlocked)
        static let afterFirstUnlock = String(kSecAttrAccessibleAfterFirstUnlock)
        static let service = String(kSecAttrService)
        static let account = String(kSecAttrAccount)
        static let returnAttributes = String(kSecReturnAttributes)
        static let returnData = String(kSecReturnData)
        static let valueData = String(kSecValueData)
    }
}



// MARK: - Debugging

extension WordPressAppDelegate {
    @objc func printDebugLaunchInfoWithLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        let unknown = "Unknown"

        let device = UIDevice.current
        let crashCount = UserDefaults.standard.integer(forKey: "crashCount")

        let extraDebug = UserDefaults.standard.bool(forKey: "extra_debug")

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        let blogs = blogService.blogsForAllAccounts()

        let accountService = AccountService(managedObjectContext: context)
        let account = accountService.defaultWordPressComAccount()

        let detailedVersionNumber = Bundle(for: type(of: self)).detailedVersionNumber() ?? unknown

        DDLogInfo("===========================================================================")
        DDLogInfo("Launching WordPress for iOS \(detailedVersionNumber)...")
        DDLogInfo("Crash count: \(crashCount)")

        #if DEBUG
            DDLogInfo("Debug mode:  Debug")
        #else
            DDLogInfo("Debug mode:  Production")
        #endif

        DDLogInfo("Extra debug: \(extraDebug ? "YES" : "NO")")

        let devicePlatform = UIDeviceHardware.platformString()
        let architecture = UIDeviceHardware.platform()
        let languages = UserDefaults.standard.array(forKey: "AppleLanguages")
        let currentLanguage = languages?.first ?? unknown
        let udid = device.wordPressIdentifier() ?? unknown

        DDLogInfo("Device model: \(devicePlatform) (\(architecture))")
        DDLogInfo("OS:        \(device.systemName), \(device.systemVersion)")
        DDLogInfo("Language:  \(currentLanguage)")
        DDLogInfo("UDID:      \(udid)")
        DDLogInfo("APN token: \(PushNotificationsManager.shared.deviceToken ?? "None")")
        DDLogInfo("Launch options: \(String(describing: launchOptions ?? [:]))")

        if let account = account,
            let username = account.username,
            let userID = account.userID {
            DDLogInfo("wp.com account: \(username) (ID: \(userID)) (\(account.verificationStatus.rawValue))")
        }

        if let blogs = blogs as? [Blog], blogs.count > 0 {
            DDLogInfo("All blogs on device:")
            blogs.forEach({ DDLogInfo("\($0.logDescription())") })
        } else {
            DDLogInfo("No blogs configured on device.")
        }

        DDLogInfo("===========================================================================")
    }

    @objc func toggleExtraDebuggingIfNeeded() {
        if !AccountHelper.isLoggedIn {
            // When there are no blogs in the app the settings screen is unavailable.
            // In this case, enable extra_debugging by default to help troubleshoot any issues.
            guard UserDefaults.standard.object(forKey: "orig_extra_debug") == nil else {
                // Already saved. Don't save again or we could loose the original value.
                return
            }

            let origExtraDebug = UserDefaults.standard.bool(forKey: "extra_debug") ? "YES" : "NO"
            UserDefaults.standard.set(origExtraDebug, forKey: "orig_extra_debug")
            UserDefaults.standard.set(true, forKey: "extra_debug")
            WordPressAppDelegate.setLogLevel(.verbose)
        } else {
            guard let origExtraDebug = UserDefaults.standard.string(forKey: "orig_extra_debug") else {
                return
            }

            let origExtraDebugValue = (origExtraDebug as NSString).boolValue

            // Restore the original setting and remove orig_extra_debug
            UserDefaults.standard.set(origExtraDebugValue, forKey: "extra_debug")
            UserDefaults.standard.removeObject(forKey: "orig_extra_debug")

            if origExtraDebugValue {
                WordPressAppDelegate.setLogLevel(.verbose)
            }
        }
    }

    @objc class func setLogLevel(_ level: DDLogLevel) {
        let rawLevel = Int32(level.rawValue)

        WPSharedSetLoggingLevel(rawLevel)
        TracksSetLoggingLevel(rawLevel)
        WPStatsSetLoggingLevel(rawLevel)
        WPAuthenticatorSetLoggingLevel(rawLevel)
    }
}

// MARK: - Local Notification Helpers

extension WordPressAppDelegate {

    @objc func addNotificationObservers() {
        let nc = NotificationCenter.default

        nc.addObserver(self,
                       selector: #selector(handleDefaultAccountChangedNotification(_:)),
                       name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(handleLowMemoryWarningNotification(_:)),
                       name: UIApplication.didReceiveMemoryWarningNotification,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(handleUIContentSizeCategoryDidChangeNotification(_:)),
                       name: UIContentSizeCategory.didChangeNotification,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(saveRecentSitesForExtensions),
                       name: .WPRecentSitesChanged,
                       object: nil)
    }

    @objc fileprivate func handleDefaultAccountChangedNotification(_ notification: NSNotification) {
        // If the notification object is not nil, then it's a login
        if notification.object != nil {
            setupShareExtensionToken()
            configureNotificationExtension()
        } else {
            trackLogoutIfNeeded()
            removeTodayWidgetConfiguration()
            removeShareExtensionConfiguration()
            removeNotificationExtensionConfiguration()
            showWelcomeScreenIfNeeded(animated: false)
        }

        toggleExtraDebuggingIfNeeded()

        WPAnalytics.track(.defaultAccountChanged)
    }

    @objc fileprivate func handleLowMemoryWarningNotification(_ notification: NSNotification) {
        WPAnalytics.track(.lowMemoryWarning)
    }

    @objc fileprivate func handleUIContentSizeCategoryDidChangeNotification(_ notification: NSNotification) {
        customizeAppearanceForTextElements()
    }
}

// MARK: - Extensions

extension WordPressAppDelegate {

    @objc func setupWordPressExtensions() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        accountService.setupAppExtensionsWithDefaultAccount()

        let maxImagesize = MediaSettings().maxImageSizeSetting
        ShareExtensionService.configureShareExtensionMaximumMediaDimension(maxImagesize)

        saveRecentSitesForExtensions()
    }

    // MARK: - Today Extension

    @objc func removeTodayWidgetConfiguration() {
        TodayExtensionService().removeTodayWidgetConfiguration()
    }

    // MARK: - Share Extension

    @objc func setupShareExtensionToken() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        if let account = accountService.defaultWordPressComAccount(), let authToken = account.authToken {
            ShareExtensionService.configureShareExtensionToken(authToken)
            ShareExtensionService.configureShareExtensionUsername(account.username)
        }
    }

    @objc func removeShareExtensionConfiguration() {
        ShareExtensionService.removeShareExtensionConfiguration()
    }

    @objc func saveRecentSitesForExtensions() {
        let recentSites = RecentSitesService().recentSites
        ShareExtensionService.configureShareExtensionRecentSites(recentSites)
    }

    // MARK: - Notification Service Extension

    @objc
    func configureNotificationExtension() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        if let account = accountService.defaultWordPressComAccount(), let authToken = account.authToken {
            NotificationSupportService.insertContentExtensionToken(authToken)
            NotificationSupportService.insertContentExtensionUsername(account.username)

            NotificationSupportService.insertServiceExtensionToken(authToken)
            NotificationSupportService.insertServiceExtensionUsername(account.username)
        }
    }

    @objc
    func removeNotificationExtensionConfiguration() {
        NotificationSupportService.deleteContentExtensionToken()
        NotificationSupportService.deleteContentExtensionUsername()

        NotificationSupportService.deleteServiceExtensionToken()
        NotificationSupportService.deleteServiceExtensionUsername()
    }
}

// MARK: - Appearance

extension WordPressAppDelegate {
    @objc func customizeAppearance() {
        window.backgroundColor = WPStyleGuide.itsEverywhereGrey()
        window.tintColor = WPStyleGuide.wordPressBlue()

        WPStyleGuide.configureNavigationBarAppearance()

        let clearImage = UIImage(color: .clear, havingSize: CGSize(width: 320.0, height: 4.0))
        UINavigationBar.appearance(whenContainedInInstancesOf: [NUXNavigationController.self]).shadowImage = clearImage
        UINavigationBar.appearance(whenContainedInInstancesOf: [NUXNavigationController.self]).setBackgroundImage(clearImage, for: .default)

        UITabBar.appearance().shadowImage = UIImage(color: UIColor(red: 210.0/255.0, green: 222.0/255.0, blue: 230.0/255.0, alpha: 1.0))
        UITabBar.appearance().tintColor = WPStyleGuide.mediumBlue()

        let navigationAppearance = UINavigationBar.appearance()
        navigationAppearance.setBackgroundImage(WPStyleGuide.navigationBarBackgroundImage(), for: .default)
        navigationAppearance.shadowImage = WPStyleGuide.navigationBarShadowImage()
        navigationAppearance.barStyle = WPStyleGuide.navigationBarBarStyle()

        UISegmentedControl.appearance().setTitleTextAttributes( [NSAttributedString.Key.font: WPStyleGuide.regularTextFont], for: .normal)
        UIToolbar.appearance().barTintColor = WPStyleGuide.wordPressBlue()
        UISwitch.appearance().onTintColor = WPStyleGuide.wordPressBlue()
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: WPStyleGuide.grey()], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: WPStyleGuide.wordPressBlue()], for: .selected)

        let navReferenceAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [UIReferenceLibraryViewController.self])
        navReferenceAppearance.setBackgroundImage(nil, for: .default)
        navReferenceAppearance.barTintColor = WPStyleGuide.wordPressBlue()

        UIToolbar.appearance(whenContainedInInstancesOf: [UIReferenceLibraryViewController.self]).barTintColor = .darkGray

        WPStyleGuide.configureSearchBarAppearance()

        // SVProgressHUD
        SVProgressHUD.setBackgroundColor(WPStyleGuide.littleEddieGrey().withAlphaComponent(0.95))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setErrorImage(UIImage(named: "hud_error")!)
        SVProgressHUD.setSuccessImage(UIImage(named: "hud_success")!)

        // Media Picker styles
        let barItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self])
        barItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: WPFontManager.systemSemiBoldFont(ofSize: 16.0)], for: .disabled)
        UICollectionView.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self]).backgroundColor = WPStyleGuide.greyLighten30()


        let cellAppearance = WPMediaCollectionViewCell.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self])
        cellAppearance.loadingBackgroundColor = WPStyleGuide.lightGrey()
        cellAppearance.placeholderBackgroundColor = WPStyleGuide.darkGrey()
        cellAppearance.placeholderTintColor = WPStyleGuide.greyLighten30()
        cellAppearance.setCellTintColor(WPStyleGuide.wordPressBlue())

        UIButton.appearance(whenContainedInInstancesOf: [WPActionBar.self]).tintColor = WPStyleGuide.wordPressBlue()

        customizeAppearanceForTextElements()
    }

    private func customizeAppearanceForTextElements() {
        let maximumPointSize = WPStyleGuide.maxFontSize

        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                            NSAttributedString.Key.font: WPStyleGuide.fixedFont(for: UIFont.TextStyle.headline, weight: UIFont.Weight.bold)]

        WPStyleGuide.configureSearchBarTextAppearance()

        SVProgressHUD.setFont(WPStyleGuide.fontForTextStyle(UIFont.TextStyle.headline, maximumPointSize: maximumPointSize))
    }
}
