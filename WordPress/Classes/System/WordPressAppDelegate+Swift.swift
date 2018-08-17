import Foundation
import CocoaLumberjack
import Reachability
import UIDeviceIdentifier
import WordPressAuthenticator


// MARK: - Utility Configuration

extension WordPressAppDelegate {
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
}

// MARK: - Debugging

extension WordPressAppDelegate {
    @objc func printDebugLaunchInfoWithLaunchOptions(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) {
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

        let devicePlatform = UIDeviceHardware.platformString() ?? unknown
        let architecture = UIDeviceHardware.platform() ?? unknown
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
            UserDefaults.standard.synchronize()
        } else {
            guard let origExtraDebug = UserDefaults.standard.string(forKey: "orig_extra_debug") else {
                return
            }

            let origExtraDebugValue = (origExtraDebug as NSString).boolValue

            // Restore the original setting and remove orig_extra_debug
            UserDefaults.standard.set(origExtraDebugValue, forKey: "extra_debug")
            UserDefaults.standard.removeObject(forKey: "orig_extra_debug")
            UserDefaults.standard.synchronize()

            if origExtraDebugValue {
                WordPressAppDelegate.setLogLevel(.verbose)
            }
        }
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
                       name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(handleUIContentSizeCategoryDidChangeNotification(_:)),
                       name: NSNotification.Name.UIContentSizeCategoryDidChange,
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

        if let account = accountService.defaultWordPressComAccount() {
            ShareExtensionService.configureShareExtensionToken(account.authToken)
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

        if let account = accountService.defaultWordPressComAccount() {
            NotificationSupportService.insertExtensionToken(account.authToken)
        }
    }

    @objc
    func removeNotificationExtensionConfiguration() {
        NotificationSupportService.deleteExtensionToken()
    }
}
