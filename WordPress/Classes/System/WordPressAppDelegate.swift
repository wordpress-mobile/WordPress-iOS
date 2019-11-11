import UIKit
import CocoaLumberjack
import Reachability
import AutomatticTracks
import WordPressAuthenticator
import WordPressShared
import AlamofireNetworkActivityIndicator
import AutomatticTracks

import ZendeskCoreSDK

class WordPressAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var analytics: WPAppAnalytics?
    var hockey: HockeyManager?
    private lazy var crashLoggingProvider: WPCrashLoggingProvider = {
        return WPCrashLoggingProvider()
    }()

    @objc var logger: WPLogger?
    @objc var internetReachability: Reachability?
    @objc var connectionAvailable: Bool = true

    // Private

    private lazy var shortcutCreator = WP3DTouchShortcutCreator()
    private var authManager: WordPressAuthenticationManager?
    private var pingHubManager: PingHubManager?
    private var noticePresenter: NoticePresenter?
    private var bgTask: UIBackgroundTaskIdentifier? = nil

    private var shouldRestoreApplicationState = false
    private var uploadsManager: UploadsManager = {
        // It's not great that we're using singletons here.  This change is a good opportunity to
        // revisit if we can make the coordinators children to another owning object.
        //
        // We're leaving as-is for now to avoid digressing.
        let uploaders: [Uploader] = [
            // Ideally we should be able to retry uploads of standalone media to the media library, but the truth is
            // that uploads started from the MediaCoordinator are currently not updating their parent post references
            // very well.  For this reason I'm disabling automated upload retries that don't start from PostCoordinator.
            //
            // MediaCoordinator.shared,
            PostCoordinator.shared
        ]

        return UploadsManager(uploaders: uploaders)
    }()

    @objc class var shared: WordPressAppDelegate? {
        return UIApplication.shared.delegate as? WordPressAppDelegate
    }

    // MARK: - Application lifecycle

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        // Configure WPCom API overrides
        configureWordPressComApi()

        configureWordPressAuthenticator()

        configureReachability()
        configureSelfHostedChallengeHandler()

        window?.makeKeyAndVisible()

        // Restore a disassociated account prior to fixing tokens.
        AccountService(managedObjectContext: ContextManager.shared.mainContext).restoreDisassociatedAccountIfNecessary()

        let solver = WPAuthTokenIssueSolver()
        let isFixingAuthTokenIssue = solver.fixAuthTokenIssueAndDo { [weak self] in
            self?.runStartupSequence(with: launchOptions ?? [:])
        }

        shouldRestoreApplicationState = !isFixingAuthTokenIssue

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DDLogInfo("didFinishLaunchingWithOptions state: \(application.applicationState)")

        let queue = DispatchQueue(label: "asd", qos: .background)
        let deviceInformation = TracksDeviceInformation()

        queue.async {
            let height = deviceInformation.statusBarHeight
            let orientation = deviceInformation.orientation!

            print("Height: \(height); orientation: \(orientation)")
        }


        InteractiveNotificationsManager.shared.registerForUserNotifications()
        showWelcomeScreenIfNeeded(animated: false)
        setupPingHub()
        setupBackgroundRefresh(application)
        setupComponentsAppearance()
        disableAnimationsForUITests(application)

        PushNotificationsManager.shared.deletePendingLocalNotifications()

        if #available(iOS 13, *) {
            startObservingAppleIDCredentialRevoked()
        }

        NotificationCenter.default.post(name: .applicationLaunchCompleted, object: nil)
        return true
    }


    func applicationWillTerminate(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        // Let the app finish any uploads that are in progress
        let app = UIApplication.shared
        if let task = bgTask, bgTask != .invalid {
            app.endBackgroundTask(task)
            bgTask = .invalid
        }

        bgTask = app.beginBackgroundTask(expirationHandler: {
            // Synchronize the cleanup call on the main thread in case
            // the task actually finishes at around the same time.
            DispatchQueue.main.async { [weak self] in
                if let task = self?.bgTask, task != .invalid {
                    app.endBackgroundTask(task)
                    self?.bgTask = .invalid
                }
            }
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        uploadsManager.resume()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        // This is done here so the check is done on app launch and app switching.
        if #available(iOS 13, *) {
            checkAppleIDCredentialState()
        }
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        let lastSavedStateVersionKey = "lastSavedStateVersionKey"
        let defaults = UserDefaults.standard

        var shouldRestoreApplicationState = false

        if let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if let lastSavedVersion = defaults.string(forKey: lastSavedStateVersionKey),
                lastSavedVersion.count > 0 && lastSavedVersion == currentVersion {
                shouldRestoreApplicationState = self.shouldRestoreApplicationState
            }

            defaults.setValue(currentVersion, forKey: lastSavedStateVersionKey)
        }

        return shouldRestoreApplicationState
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handler = WP3DTouchShortcutHandler()
        completionHandler(handler.handleShortcutItem(shortcutItem))
    }

    func application(_ application: UIApplication, viewControllerWithRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        guard let restoreID = identifierComponents.last else {
            return nil
        }

        return Restorer().viewController(identifier: restoreID)
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // 21-Oct-2017: We are only handling background URLSessions initiated by the share extension so there
        // is no need to inspect the identifier beyond the simple check here.
        if identifier.contains(WPAppGroupName) {
            let manager = ShareExtensionSessionManager(appGroup: WPAppGroupName, backgroundSessionIdentifier: identifier)
            manager.backgroundSessionCompletionBlock = completionHandler
            manager.startBackgroundSession()
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            handleWebActivity(userActivity)
        } else {
            // Spotlight search
            SearchManager.shared.handle(activity: userActivity)
        }

        return true
    }

    // MARK: - Setup

    func runStartupSequence(with launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]) {
        // Local notifications
        addNotificationObservers()

        logger = WPLogger()

        CrashLogging.start(withDataProvider: crashLoggingProvider)

        configureHockeySDK()
        configureAppRatingUtility()
        configureAnalytics()

        printDebugLaunchInfoWithLaunchOptions(launchOptions)
        toggleExtraDebuggingIfNeeded()

        #if DEBUG
        KeychainTools.processKeychainDebugArguments()
        CoreLogger.enabled = true
        CoreLogger.logLevel = .debug
        #endif

        ZendeskUtils.setup()

        setupNetworkActivityIndicator()
        WPUserAgent.useWordPressInUIWebViews()

        // WORKAROUND: Preload the Noto regular font to ensure it is not overridden
        // by any of the Noto varients.  Size is arbitrary.
        // See: https://github.com/wordpress-mobile/WordPress-Shared-iOS/issues/79
        // Remove this when #79 is resolved.
        WPFontManager.notoRegularFont(ofSize: 16.0)

        customizeAppearance()

        // Push notifications
        // This is silent (the user isn't prompted) so we can do it on launch.
        // We'll ask for user notification permission after signin.
        PushNotificationsManager.shared.registerForRemoteNotifications()

        // Deferred tasks to speed up app launch
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.mergeDuplicateAccountsIfNeeded()
            MediaCoordinator.shared.refreshMediaStatus()
            PostCoordinator.shared.refreshPostStatus()
            MediaFileManager.clearUnusedMediaUploadFiles(onCompletion: nil, onError: nil)
            self?.uploadsManager.resume()
        }

        setupWordPressExtensions()

        shortcutCreator.createShortcutsIf3DTouchAvailable(AccountHelper.isLoggedIn)

        window?.rootViewController = WPTabBarController.sharedInstance()

        setupNoticePresenter()
    }

    private func mergeDuplicateAccountsIfNeeded() {
        let context = ContextManager.shared.mainContext
        context.perform {
            AccountService(managedObjectContext: ContextManager.shared.mainContext).mergeDuplicatesIfNecessary()
        }
    }

    private func setupPingHub() {
        pingHubManager = PingHubManager()
    }

    private func setupShortcutCreator() {
        shortcutCreator = WP3DTouchShortcutCreator()
    }

    private func setupNoticePresenter() {
        noticePresenter = NoticePresenter()
    }

    private func setupBackgroundRefresh(_ application: UIApplication) {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }

    // MARK: - Helpers

    /// This method will disable animations and speed-up keyboad input if command-line arguments includes "NoAnimations"
    /// It was designed to be used in UI test suites. To enable it just pass a launch argument into XCUIApplicaton:
    ///
    /// XCUIApplication().launchArguments = ["-no-animations"]
    ///
    private func disableAnimationsForUITests(_ application: UIApplication) {
        if CommandLine.arguments.contains("-no-animations") {
            UIView.setAnimationsEnabled(false)
            application.windows.first?.layer.speed = MAXFLOAT
            application.keyWindow?.layer.speed = MAXFLOAT
        }
    }

    var runningInBackground: Bool {
        return UIApplication.shared.applicationState == .background
    }
}

/// Declares Notification Names
extension Foundation.Notification.Name {
    static var applicationLaunchCompleted: Foundation.NSNotification.Name {
        return Foundation.Notification.Name("org.wordpress.startup.completed")
    }
}

// MARK: - Push Notification Delegate

extension WordPressAppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationsManager.shared.registerDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationsManager.shared.registrationDidFail(error as NSError)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogInfo("\(self) \(#function)")

        PushNotificationsManager.shared.handleNotification(userInfo as NSDictionary,
                                                           completionHandler: completionHandler)
    }

    // MARK: Background refresh

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let tabBarController = WPTabBarController.sharedInstance()

        if let readerMenu = tabBarController?.readerMenuViewController,
            let stream = readerMenu.currentReaderStream {
            stream.backgroundFetch(completionHandler)
        } else {
            completionHandler(.noData)
        }
    }
}

// MARK: - Utility Configuration

extension WordPressAppDelegate {

    func configureAnalytics() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        analytics = WPAppAnalytics(accountService: accountService,
                                   lastVisibleScreenBlock: { [weak self] in
                                    return self?.currentlySelectedScreen
        })
    }

    func configureAppRatingUtility() {
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

    @objc func configureHockeySDK() {
        hockey = HockeyManager()
        hockey?.configure()
    }

    func configureReachability() {
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

        internetReachability?.reachableBlock = reachabilityBlock
        internetReachability?.unreachableBlock = reachabilityBlock

        internetReachability?.startNotifier()

        connectionAvailable = internetReachability?.isReachable() ?? true
    }

    func configureSelfHostedChallengeHandler() {
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

        authManager?.initializeWordPressAuthenticator()
        authManager?.startRelayingSupportNotifications()

        WordPressAuthenticator.shared.delegate = authManager
    }

    func handleWebActivity(_ activity: NSUserActivity) {
        guard AccountHelper.isLoggedIn,
            activity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = activity.webpageURL else {
                FailureNavigationAction().failAndBounce(activity.webpageURL)
                return
        }

        UniversalLinkRouter.shared.handle(url: url)
    }

    @objc func setupNetworkActivityIndicator() {
        NetworkActivityIndicatorManager.shared.isEnabled = true
    }

    @objc func configureWordPressComApi() {
        if let baseUrl = UserDefaults.standard.string(forKey: "wpcom-api-base-url") {
            Environment.replaceEnvironment(wordPressComApiBase: baseUrl)
        }
    }
}

// MARK: - UIAppearance

extension WordPressAppDelegate {

    /// Sets up all of the shared component(s) Appearance.
    ///
    func setupComponentsAppearance() {
        setupFancyAlertAppearance()
        setupFancyButtonAppearance()
    }


    /// Setup: FancyAlertView's Appearance
    ///
    private func setupFancyAlertAppearance() {
        let appearance = FancyAlertView.appearance()

        appearance.titleTextColor = .neutral(.shade70)
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)

        appearance.bodyTextColor = .neutral(.shade70)
        appearance.bodyFont = WPStyleGuide.fontForTextStyle(.body)
        appearance.bodyBackgroundColor = .neutral(.shade0)

        appearance.actionFont = WPStyleGuide.fontForTextStyle(.headline)
        appearance.infoFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        appearance.infoTintColor = WPStyleGuide.wordPressBlue()

        appearance.topDividerColor = .neutral(.shade5)
        appearance.bottomDividerColor = .neutral(.shade0)
        appearance.headerBackgroundColor = .neutral(.shade0)

        appearance.bottomBackgroundColor = .neutral(.shade0)
    }

    /// Setup: FancyButton's Appearance
    ///
    private func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.headline)
        appearance.primaryTitleColor = .white
        appearance.primaryNormalBackgroundColor = .primaryButtonBackground
        appearance.primaryHighlightBackgroundColor = .primaryButtonDownBackground

        appearance.secondaryTitleColor = .text
        appearance.secondaryNormalBackgroundColor = .secondaryButtonBackground
        appearance.secondaryNormalBorderColor = .secondaryButtonBorder
        appearance.secondaryHighlightBackgroundColor = .secondaryButtonDownBackground
        appearance.secondaryHighlightBorderColor = .secondaryButtonDownBorder

        appearance.disabledTitleColor = .neutral(.shade20)
        appearance.disabledBackgroundColor = .textInverted
        appearance.disabledBorderColor = .neutral(.shade10)
    }
}


// MARK: - Helpers

extension WordPressAppDelegate {

    var currentlySelectedScreen: String {
        // Check if the post editor or login view is up
        let rootViewController = window?.rootViewController
        if let presentedViewController = rootViewController?.presentedViewController {
            if presentedViewController is EditPostViewController {
                return "Post Editor"
            } else if presentedViewController is LoginNavigationController {
                return "Login View"
            }
        }

        return WPTabBarController.sharedInstance().currentlySelectedScreen()
    }

    var isWelcomeScreenVisible: Bool {
        get {
            guard let presentedViewController = window?.rootViewController?.presentedViewController as? UINavigationController else {
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
        if let presenter = window?.rootViewController?.presentedViewController,
            !(presenter is UIAlertController) {
            presenter.dismiss(animated: animated, completion: { [weak self] in
                self?.showWelcomeScreen(animated, thenEditor: false)
            })
        } else {
            showWelcomeScreen(animated, thenEditor: false)
        }
    }

    func showWelcomeScreen(_ animated: Bool, thenEditor: Bool) {
        if let rootViewController = window?.rootViewController {
            WordPressAuthenticator.showLogin(from: rootViewController, animated: animated)
        }
    }

    @objc func trackLogoutIfNeeded() {
        if AccountHelper.isLoggedIn == false {
            WPAnalytics.track(.logout)
        }
    }
}

// MARK: - Debugging

extension WordPressAppDelegate {
    func printDebugLaunchInfoWithLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        let unknown = "Unknown"

        let device = UIDevice.current
        let crashCount = UserDefaults.standard.integer(forKey: "crashCount")

        let extraDebug = UserDefaults.standard.bool(forKey: "extra_debug")

        let context = ContextManager.sharedInstance().mainContext

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

        AccountHelper.logBlogsAndAccounts(context: context)
        DDLogInfo("===========================================================================")
    }

    func toggleExtraDebuggingIfNeeded() {
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
        WPAuthenticatorSetLoggingLevel(rawLevel)
    }
}

// MARK: - Local Notification Helpers

extension WordPressAppDelegate {

    func addNotificationObservers() {
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

            if #available(iOS 13, *) {
                startObservingAppleIDCredentialRevoked()
            }
        } else {
            trackLogoutIfNeeded()
            removeTodayWidgetConfiguration()
            removeShareExtensionConfiguration()
            removeNotificationExtensionConfiguration()
            showWelcomeScreenIfNeeded(animated: false)

            if #available(iOS 13, *) {
                stopObservingAppleIDCredentialRevoked()
            }
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

    func setupWordPressExtensions() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        accountService.setupAppExtensionsWithDefaultAccount()

        let maxImagesize = MediaSettings().maxImageSizeSetting
        ShareExtensionService.configureShareExtensionMaximumMediaDimension(maxImagesize)

        saveRecentSitesForExtensions()
    }

    // MARK: - Today Extension

    func removeTodayWidgetConfiguration() {
        TodayExtensionService().removeTodayWidgetConfiguration()
    }

    // MARK: - Share Extension

    func setupShareExtensionToken() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        if let account = accountService.defaultWordPressComAccount(), let authToken = account.authToken {
            ShareExtensionService.configureShareExtensionToken(authToken)
            ShareExtensionService.configureShareExtensionUsername(account.username)
        }
    }

    func removeShareExtensionConfiguration() {
        ShareExtensionService.removeShareExtensionConfiguration()
    }

    @objc func saveRecentSitesForExtensions() {
        let recentSites = RecentSitesService().recentSites
        ShareExtensionService.configureShareExtensionRecentSites(recentSites)
    }

    // MARK: - Notification Service Extension

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

    func removeNotificationExtensionConfiguration() {
        NotificationSupportService.deleteContentExtensionToken()
        NotificationSupportService.deleteContentExtensionUsername()

        NotificationSupportService.deleteServiceExtensionToken()
        NotificationSupportService.deleteServiceExtensionUsername()
    }
}

// MARK: - Appearance

extension WordPressAppDelegate {
    func customizeAppearance() {
        window?.backgroundColor = .black
        window?.tintColor = WPStyleGuide.wordPressBlue()

        WPStyleGuide.configureTabBarAppearance()
        WPStyleGuide.configureNavigationAppearance()
        WPStyleGuide.configureDefaultTint()
        WPStyleGuide.configureLightNavigationBarAppearance()

        UISegmentedControl.appearance().setTitleTextAttributes( [NSAttributedString.Key.font: WPStyleGuide.regularTextFont()], for: .normal)
        UIToolbar.appearance().barTintColor = .primary
        UISwitch.appearance().onTintColor = .primary

        let navReferenceAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [UIReferenceLibraryViewController.self])
        navReferenceAppearance.setBackgroundImage(nil, for: .default)
        navReferenceAppearance.barTintColor = .primary

        UIToolbar.appearance(whenContainedInInstancesOf: [UIReferenceLibraryViewController.self]).barTintColor = .darkGray

        WPStyleGuide.configureSearchBarAppearance()

        // SVProgressHUD
        SVProgressHUD.setBackgroundColor(UIColor.neutral(.shade70).withAlphaComponent(0.95))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setErrorImage(UIImage(named: "hud_error")!)
        SVProgressHUD.setSuccessImage(UIImage(named: "hud_success")!)

        // Media Picker styles
        let barItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self])
        barItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: WPFontManager.systemSemiBoldFont(ofSize: 16.0)], for: .disabled)
        UICollectionView.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self]).backgroundColor = .neutral(.shade5)


        let cellAppearance = WPMediaCollectionViewCell.appearance(whenContainedInInstancesOf: [WPMediaPickerViewController.self])
        cellAppearance.loadingBackgroundColor = .listBackground
        cellAppearance.placeholderBackgroundColor = .neutral(.shade70)
        cellAppearance.placeholderTintColor = .neutral(.shade5)
        cellAppearance.setCellTintColor(.primary)

        UIButton.appearance(whenContainedInInstancesOf: [WPActionBar.self]).tintColor = .primary

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

// MARK: - Apple Account Handling

@available(iOS 13.0, *)
extension WordPressAppDelegate {

    func checkAppleIDCredentialState() {

        // If not logged in, remove the Apple User ID from the keychain, if it exists.
        guard AccountHelper.isLoggedIn else {
            removeAppleIDFromKeychain()
            return
        }

        // Get the Apple User ID from the keychain
        let appleUserID: String
        do {
            appleUserID = try SFHFKeychainUtils.getPasswordForUsername(WPAppleIDKeychainUsernameKey,
                                                                  andServiceName: WPAppleIDKeychainServiceName)
        } catch {
            DDLogInfo("checkAppleIDCredentialState: No Apple ID found.")
            return
        }

        // Get the Apple User ID state. If not authorized, log out the account.
        WordPressAuthenticator.shared.getAppleIDCredentialState(for: appleUserID) { [weak self] (state, error) in

            DDLogDebug("checkAppleIDCredentialState: Apple ID state: \(state.rawValue)")

            switch state {
            case .revoked:
                DDLogInfo("checkAppleIDCredentialState: Revoked Apple ID. User signed out.")
                self?.logOutRevokedAppleAccount()
            default:
                // An error exists only for the notFound state.
                // notFound is a valid state when logging in with an Apple account for the first time.
                if let error = error {
                    DDLogDebug("checkAppleIDCredentialState: Apple ID state not found: \(error.localizedDescription)")
                }
                break
            }
        }
    }

    func startObservingAppleIDCredentialRevoked() {
        WordPressAuthenticator.shared.startObservingAppleIDCredentialRevoked { [weak self] in
            if AccountHelper.isLoggedIn {
                DDLogInfo("Apple credentialRevokedNotification received. User signed out.")
                self?.logOutRevokedAppleAccount()
            }
        }
    }

    func stopObservingAppleIDCredentialRevoked() {
        WordPressAuthenticator.shared.stopObservingAppleIDCredentialRevoked()
    }

    func logOutRevokedAppleAccount() {
        removeAppleIDFromKeychain()
        logOutDefaultWordPressComAccount()
    }

    func logOutDefaultWordPressComAccount() {
        DispatchQueue.main.async {
            AccountHelper.logOutDefaultWordPressComAccount()
        }
    }

    func removeAppleIDFromKeychain() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPAppleIDKeychainUsernameKey,
                                             andServiceName: WPAppleIDKeychainUsernameKey)
        } catch let error as NSError {
            if error.code != errSecItemNotFound {
                DDLogError("Error while removing Apple User ID from keychain: \(error.localizedDescription)")
            }
        }
    }

}
