import Foundation
import CocoaLumberjack
import Reachability
import UIDeviceIdentifier

// MARK: - Utility Configuration

extension WordPressAppDelegate {
    @objc func configureAnalytics() {
        analytics = WPAppAnalytics(lastVisibleScreenBlock: { [weak self] in
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
            self?.connectionAvailable = reachability.isReachable()
        }

        internetReachability.reachableBlock = reachabilityBlock
        internetReachability.unreachableBlock = reachabilityBlock

        internetReachability.startNotifier()

        connectionAvailable = internetReachability.isReachable()
    }

    @objc func configureWordPressAuthenticator() {
        authManager = WordPressAuthenticationManager()
        WordPressAuthenticator.shared.delegate = authManager

        WordPressAuthenticationTracker.shared.startListeningToAuthenticationEvents()
    }
}

// MARK: - Helpers

extension WordPressAppDelegate {
    @objc var noSelfHostedBlogs: Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return blogService.blogCountSelfHosted() == 0 && blogService.hasAnyJetpackBlogs() == false
    }

    @objc var noWordPressDotComAccount: Bool {
        return !AccountHelper.isDotcomAvailable()
    }

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

            return visibleViewController is NUXAbstractViewController
                || visibleViewController is LoginPrologueViewController
                || visibleViewController is NUXViewControllerBase
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
            let userID = account.userID,
            let verificationStatus = account.verificationStatus() {
            DDLogInfo("wp.com account: \(username) (ID: \(userID)) (\(verificationStatus))")
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
        if noSelfHostedBlogs && noWordPressDotComAccount {
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
            UserDefaults.resetStandardUserDefaults()
        } else {
            guard let origExtraDebug = UserDefaults.standard.string(forKey: "orig_extra_debug") else {
                return
            }

            let origExtraDebugValue = (origExtraDebug as NSString).boolValue

            // Restore the original setting and remove orig_extra_debug
            UserDefaults.standard.set(origExtraDebugValue, forKey: "extra_debug")
            UserDefaults.standard.removeObject(forKey: "orig_extra_debug")
            UserDefaults.resetStandardUserDefaults()

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
    }

    @objc fileprivate func handleDefaultAccountChangedNotification(_ notification: NSNotification) {
        // If the notification object is not nil, then it's a login
        if notification.object != nil {
            setupShareExtensionToken()
        } else {
            trackLogoutIfNeeded()
            removeTodayWidgetConfiguration()
            removeShareExtensionConfiguration()
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
}
