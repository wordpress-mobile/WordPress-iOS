import UIKit
import CocoaLumberjack
import Reachability
import AutomatticTracks
import WordPressAuthenticator
import WordPressShared
import AlamofireNetworkActivityIndicator
import AutomatticAbout

#if APPCENTER_ENABLED
import AppCenter
import AppCenterDistribute
#endif

import ZendeskCoreSDK

class WordPressAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let backgroundTasksCoordinator = BackgroundTasksCoordinator(tasks: [
        WeeklyRoundupBackgroundTask()
    ], eventHandler: WordPressBackgroundTaskEventHandler())

    @objc
    lazy var windowManager: WindowManager = {
        guard let window = window else {
            fatalError("The App cannot run without a window.")
        }

        return AppDependency.windowManager(window: window)
    }()

    var analytics: WPAppAnalytics?

    @objc var internetReachability: Reachability?
    @objc var connectionAvailable: Bool = true

    // Private

    private lazy var shortcutCreator = WP3DTouchShortcutCreator()
    private var authManager: WordPressAuthenticationManager?
    private var pingHubManager: PingHubManager?
    private var noticePresenter: NoticePresenter?
    private var bgTask: UIBackgroundTaskIdentifier? = nil
    private let remoteFeatureFlagStore = RemoteFeatureFlagStore()
    private let remoteConfigStore = RemoteConfigStore()

    private var mainContext: NSManagedObjectContext {
        return ContextManager.shared.mainContext
    }

    private var shouldRestoreApplicationState = false
    private lazy var uploadsManager: UploadsManager = {

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

    private let loggingStack = WPLoggingStack()

    /// Access the crash logging type
    class var crashLogging: CrashLogging? {
        shared?.loggingStack.crashLogging
    }

    /// Access the event logging type
    class var eventLogging: EventLogging? {
        shared?.loggingStack.eventLogging
    }

    @objc class var shared: WordPressAppDelegate? {
        assert(Thread.isMainThread, "WordPressAppDelegate.shared can only be accessed from the main thread")
        return UIApplication.shared.delegate as? WordPressAppDelegate
    }

    // MARK: - Application lifecycle

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        AppAppearance.overrideAppearance()
        MemoryCache.shared.register()
        MediaImageService.migrateCacheIfNeeded()
        PostCoordinator.shared.delegate = self

        // Start CrashLogging as soon as possible (in case a crash happens during startup)
        try? loggingStack.start()

        // Configure WPCom API overrides
        configureWordPressComApi()

        configureWordPressAuthenticator()

        configureReachability()
        configureSelfHostedChallengeHandler()
        updateFeatureFlags()
        updateRemoteConfig()

        window?.makeKeyAndVisible()

        // Restore a disassociated account prior to fixing tokens.
        AccountService(coreDataStack: ContextManager.sharedInstance()).restoreDisassociatedAccountIfNecessary()

        customizeAppearance()
        configureAnalytics()

        let solver = WPAuthTokenIssueSolver()
        let isFixingAuthTokenIssue = solver.fixAuthTokenIssueAndDo { [weak self] in
            self?.runStartupSequence(with: launchOptions ?? [:])
        }

        shouldRestoreApplicationState = !isFixingAuthTokenIssue

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DDLogInfo("didFinishLaunchingWithOptions state: \(application.applicationState)")

        ABTest.start()

        Media.removeTemporaryData()
        InteractiveNotificationsManager.shared.registerForUserNotifications()
        setupPingHub()
        setupBackgroundRefresh(application)
        setupComponentsAppearance()
        UITestConfigurator.prepareApplicationForUITests(application)
        DebugMenuViewController.configure(in: window)

        // This was necessary to properly load fonts for the Stories editor. I believe external libraries may require this call to access fonts.
        let fonts = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
        fonts?.forEach({ url in
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        })

        PushNotificationsManager.shared.deletePendingLocalNotifications()

        startObservingAppleIDCredentialRevoked()

        NotificationCenter.default.post(name: .applicationLaunchCompleted, object: nil)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        let app = UIApplication.shared

        // Let the app finish any uploads that are in progress
        if let task = bgTask, bgTask != .invalid {
            DDLogInfo("BackgroundTask: ending existing backgroundTask for bgTask = \(task.rawValue)")
            app.endBackgroundTask(task)
            bgTask = .invalid
        }

        bgTask = app.beginBackgroundTask(expirationHandler: { [weak self] in
            // WARNING: The task has to be terminated immediately on expiration
            if let task = self?.bgTask, task != .invalid {
                DDLogInfo("BackgroundTask: executing expirationHandler for bgTask = \(task.rawValue)")
                app.endBackgroundTask(task)
                self?.bgTask = .invalid
            }
        })

        if let bgTask = bgTask {
            DDLogInfo("BackgroundTask: beginBackgroundTask for bgTask = \(bgTask.rawValue)")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        uploadsManager.resume()
        updateFeatureFlags()
        updateRemoteConfig()

#if JETPACK
        // JetpackWindowManager is only available in the Jetpack target.
        if let windowManager = windowManager as? JetpackWindowManager {
            windowManager.startMigrationFlowIfNeeded()
        }
#endif
    }

    func applicationWillResignActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        // This is done here so the check is done on app launch and app switching.
        checkAppleIDCredentialState()

        GutenbergSettings().performGutenbergPhase2MigrationIfNeeded()
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        let lastSavedStateVersionKey = "lastSavedStateVersionKey"
        let defaults = UserPersistentStoreFactory.instance()

        var shouldRestoreApplicationState = false

        if let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if let lastSavedVersion = defaults.string(forKey: lastSavedStateVersionKey),
                lastSavedVersion.count > 0 && lastSavedVersion == currentVersion {
                shouldRestoreApplicationState = self.shouldRestoreApplicationState
            }

            defaults.set(currentVersion, forKey: lastSavedStateVersionKey)
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

    // Note that this method only appears to be called for iPhone devices, not iPad.
    // This allows individual view controllers to cancel rotation if they need to.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let vc = window?.topmostPresentedViewController,
           vc is OrientationLimited {
            return vc.supportedInterfaceOrientations
        }

        return application.supportedInterfaceOrientations(for: window)
    }

    // MARK: - Setup

    func runStartupSequence(with launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]) {
        // Local notifications
        addNotificationObservers()

        configureAppCenterSDK()
        configureAppRatingUtility()

        let libraryLogger = WordPressLibraryLogger()
        TracksLogging.delegate = libraryLogger
        WPSharedSetLoggingDelegate(libraryLogger)
        WPKitSetLoggingDelegate(libraryLogger)
        WPAuthenticatorSetLoggingDelegate(libraryLogger)

        printDebugLaunchInfoWithLaunchOptions(launchOptions)
        toggleExtraDebuggingIfNeeded()

        #if DEBUG
        KeychainTools.processKeychainDebugArguments()

        // Zendesk Logging
        CoreLogger.enabled = true
        CoreLogger.logLevel = .debug
        #endif

        ZendeskUtils.setup()

        setupNetworkActivityIndicator()
        WPUserAgent.useWordPressInWebViews()

        // Push notifications
        // This is silent (the user isn't prompted) so we can do it on launch.
        // We'll ask for user notification permission after signin.
        DispatchQueue.main.async {
            PushNotificationsManager.shared.setupRemoteNotifications()
        }

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

        AccountService.loadDefaultAccountCookies()

        windowManager.showUI()
        setupNoticePresenter()
    }

    private func mergeDuplicateAccountsIfNeeded() {
        AccountService(coreDataStack: ContextManager.sharedInstance()).mergeDuplicatesIfNecessary()
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
        backgroundTasksCoordinator.scheduleTasks { result in
            if case .failure(let error) = result {
                DDLogError("Error scheduling background tasks: \(error)")
            }
        }
    }

    // MARK: - Helpers

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

}

// MARK: - Utility Configuration

extension WordPressAppDelegate {

    func configureAnalytics() {
        analytics = WPAppAnalytics(lastVisibleScreenBlock: { [weak self] in
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
    }

    @objc func configureAppCenterSDK() {
        #if APPCENTER_ENABLED
        AppCenter.start(withAppSecret: ApiCredentials.appCenterAppId, services: [Distribute.self])
        #endif
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
        let authManager = AppDependency.authenticationManager(windowManager: windowManager)

        authManager.initializeWordPressAuthenticator()
        authManager.startRelayingSupportNotifications()

        WordPressAuthenticator.shared.delegate = authManager
        self.authManager = authManager
    }

    func handleWebActivity(_ activity: NSUserActivity) {
        // try to handle unauthenticated routes first.
        if activity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = activity.webpageURL,
           UniversalLinkRouter.unauthenticated.canHandle(url: url) {
            UniversalLinkRouter.unauthenticated.handle(url: url)
            return
        }

        guard AccountHelper.isLoggedIn,
            activity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = activity.webpageURL else {
                FailureNavigationAction().failAndBounce(activity.webpageURL)
                return
        }

        if QRLoginCoordinator.didHandle(url: url) {
            return
        }

        /// If the counterpart WordPress/Jetpack app is installed, and the URL has a wp-admin link equivalent,
        /// bounce the wp-admin link to Safari instead.
        ///
        /// Passing a URL that the router couldn't handle results in opening the URL in Safari, which will
        /// cause the other app to "catch" the intent — and leads to a navigation loop between the two apps.
        ///
        /// TODO: Remove this after the Universal Link routes for the WordPress app are removed.
        ///
        /// Read more: https://github.com/wordpress-mobile/WordPress-iOS/issues/19755
        if MigrationAppDetection.isCounterpartAppInstalled,
           WPAdminConvertibleRouter.shared.canHandle(url: url) {
            WPAdminConvertibleRouter.shared.handle(url: url)
            return
        }

        trackDeepLink(for: url) { url in
            UniversalLinkRouter.shared.handle(url: url)
        }
    }

    @objc func setupNetworkActivityIndicator() {
        NetworkActivityIndicatorManager.shared.isEnabled = true
    }

    @objc func configureWordPressComApi() {
        if let baseUrl = UserPersistentStoreFactory.instance().string(forKey: "wpcom-api-base-url") {
            Environment.replaceEnvironment(wordPressComApiBase: baseUrl)
        }
    }
}

// MARK: - Deep Link Handling

extension WordPressAppDelegate {

    private func trackDeepLink(for url: URL, completion: @escaping ((URL) -> Void)) {
        guard isIterableDeepLink(url) else {
            completion(url)
            return
        }

        let task = URLSession.shared.dataTask(with: url) {(_, response, error) in
            if let url = response?.url {
                completion(url)
            }
        }
        task.resume()
    }

    private func isIterableDeepLink(_ url: URL) -> Bool {
        return url.absoluteString.contains(WordPressAppDelegate.iterableDomain)
    }

    private static let iterableDomain = "links.wp.a8cmail.com"
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
        appearance.infoTintColor = .primary

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
        guard let rootViewController = window?.rootViewController else {
            DDLogInfo("\(#function) is called when `rootViewController` is nil.")
            return String()
        }

        // NOTE: This logic doesn't cover all the scenarios properly yet. If we want to know what screen was actually seen,
        // there should be a recursive check to get to the visible view controller (or call `UINavigationController`'s `visibleViewController`).
        //
        // Read more here: https://github.com/wordpress-mobile/WordPress-iOS/pull/19677#pullrequestreview-1199885009
        //
        switch rootViewController.presentedViewController ?? rootViewController {
        case is EditPostViewController:
            return "Post Editor"
        case is LoginNavigationController:
            return "Login View"
#if JETPACK
        case is MigrationNavigationController:
            return "Jetpack Migration View"
        case is MigrationLoadWordPressViewController:
            return "Jetpack Migration Load WordPress View"
#endif
        default:
            return RootViewCoordinator.sharedPresenter.currentlySelectedScreen()
        }
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

    @objc func trackLogoutIfNeeded() {
        if AccountHelper.isLoggedIn == false {
            WPAnalytics.track(.logout)
        }
    }

    /// Updates the remote feature flags using an authenticated remote if a token is provided or an account exists
    /// Otherwise an anonymous remote will be used
    func updateFeatureFlags(authToken: String? = nil, completion: (() -> Void)? = nil) {
        var api: WordPressComRestApi
        if let authToken {
            api = WordPressComRestApi.defaultV2Api(authToken: authToken)
        } else {
            api = WordPressComRestApi.defaultV2Api(in: mainContext)
        }
        let remote = FeatureFlagRemote(wordPressComRestApi: api)
        remoteFeatureFlagStore.update(using: remote, then: completion)
    }

    func updateRemoteConfig() {
        remoteConfigStore.update()
    }
}

// MARK: - Debugging

extension WordPressAppDelegate {
    func printDebugLaunchInfoWithLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        let unknown = "Unknown"

        let device = UIDevice.current
        let crashCount = UserPersistentStoreFactory.instance().integer(forKey: "crashCount")

        let extraDebug = UserPersistentStoreFactory.instance().bool(forKey: "extra_debug")

        let bundle = Bundle.main
        let detailedVersionNumber = bundle.detailedVersionNumber() ?? unknown
        let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? unknown

        DDLogInfo("===========================================================================")
        DDLogInfo("Launching \(appName) for iOS \(detailedVersionNumber)...")
        DDLogInfo("Crash count: \(crashCount)")

        #if DEBUG
        DDLogInfo("Debug mode:  Debug")
        #else
        DDLogInfo("Debug mode:  Production")
        #endif

        DDLogInfo("Extra debug: \(extraDebug ? "YES" : "NO")")

        let devicePlatform = UIDeviceHardware.platformString()
        let architecture = UIDeviceHardware.platform()
        let languages = UserPersistentStoreFactory.instance().array(forKey: "AppleLanguages")
        let currentLanguage = languages?.first ?? unknown
        let udid = device.wordPressIdentifier() ?? unknown

        DDLogInfo("Device model: \(devicePlatform) (\(architecture))")
        DDLogInfo("OS:        \(device.systemName), \(device.systemVersion)")
        DDLogInfo("Language:  \(currentLanguage)")
        DDLogInfo("UDID:      \(udid)")
        DDLogInfo("APN token: \(PushNotificationsManager.shared.deviceToken ?? "None")")
        DDLogInfo("Launch options: \(String(describing: launchOptions ?? [:]))")

        AccountHelper.logBlogsAndAccounts(context: mainContext)
        DDLogInfo("===========================================================================")
    }

    func toggleExtraDebuggingIfNeeded() {
        if !AccountHelper.isLoggedIn {
            // When there are no blogs in the app the settings screen is unavailable.
            // In this case, enable extra_debugging by default to help troubleshoot any issues.
            guard UserPersistentStoreFactory.instance().object(forKey: "orig_extra_debug") == nil else {
                // Already saved. Don't save again or we could loose the original value.
                return
            }

            let origExtraDebug = UserPersistentStoreFactory.instance().bool(forKey: "extra_debug") ? "YES" : "NO"
            UserPersistentStoreFactory.instance().set(origExtraDebug, forKey: "orig_extra_debug")
            UserPersistentStoreFactory.instance().set(true, forKey: "extra_debug")
            WordPressAppDelegate.setLogLevel(.verbose)
        } else {
            guard let origExtraDebug = UserPersistentStoreFactory.instance().string(forKey: "orig_extra_debug") else {
                return
            }

            let origExtraDebugValue = (origExtraDebug as NSString).boolValue

            // Restore the original setting and remove orig_extra_debug
            UserPersistentStoreFactory.instance().set(origExtraDebugValue, forKey: "extra_debug")
            UserPersistentStoreFactory.instance().removeObject(forKey: "orig_extra_debug")

            if origExtraDebugValue {
                WordPressAppDelegate.setLogLevel(.verbose)
            }
        }
    }

    @objc class func setLogLevel(_ level: DDLogLevel) {
        SetCocoaLumberjackObjCLogLevel(level.rawValue)
        CocoaLumberjack.dynamicLogLevel = level
    }

    /// Logs the error in Sentry.
    @objc class func logError(_ error: Error) {
        crashLogging?.logError(error)
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
                       selector: #selector(saveRecentSitesForExtensions),
                       name: .WPRecentSitesChanged,
                       object: nil)
    }

    @objc fileprivate func handleDefaultAccountChangedNotification(_ notification: NSNotification) {
        // If the notification object is not nil, then it's a login
        if notification.object != nil {
            setupWordPressExtensions()
            startObservingAppleIDCredentialRevoked()
            AccountService.loadDefaultAccountCookies()
        } else {
            trackLogoutIfNeeded()
            removeShareExtensionConfiguration()
            removeNotificationExtensionConfiguration()
            windowManager.showFullscreenSignIn()
            stopObservingAppleIDCredentialRevoked()
        }

        toggleExtraDebuggingIfNeeded()

        WPAnalytics.track(.defaultAccountChanged)
    }

    @objc fileprivate func handleLowMemoryWarningNotification(_ notification: NSNotification) {
        WPAnalytics.track(.lowMemoryWarning)
    }
}

// MARK: - Extensions

extension WordPressAppDelegate {

    func setupWordPressExtensions() {
        let accountService = AccountService(coreDataStack: ContextManager.sharedInstance())
        accountService.setupAppExtensionsWithDefaultAccount()

        let maxImagesize = MediaSettings().maxImageSizeSetting
        ShareExtensionService.configureShareExtensionMaximumMediaDimension(maxImagesize)

        saveRecentSitesForExtensions()
    }

    // MARK: - Share Extension

    func setupShareExtensionToken() {

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext), let authToken = account.authToken {
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

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext), let authToken = account.authToken {
            NotificationSupportService.insertContentExtensionToken(authToken)
            NotificationSupportService.insertContentExtensionUsername(account.username)

            NotificationSupportService.insertServiceExtensionToken(authToken)
            NotificationSupportService.insertServiceExtensionUsername(account.username)
            NotificationSupportService.insertServiceExtensionUserID(account.userID.stringValue)
        }
    }

    func removeNotificationExtensionConfiguration() {
        NotificationSupportService.deleteContentExtensionToken()
        NotificationSupportService.deleteContentExtensionUsername()

        NotificationSupportService.deleteServiceExtensionToken()
        NotificationSupportService.deleteServiceExtensionUsername()
        NotificationSupportService.deleteServiceExtensionUserID()
    }
}

// MARK: - Appearance

extension WordPressAppDelegate {
    func customizeAppearance() {
        window?.backgroundColor = .black
        window?.tintColor = .primary

        // iOS 14 started rendering backgrounds for stack views, when previous versions
        // of iOS didn't show them. This is a little hacky, but ensures things keep
        // looking the same on newer versions of iOS.
        UIStackView.appearance().backgroundColor = .clear

        WPStyleGuide.configureTabBarAppearance()
        WPStyleGuide.configureNavigationAppearance()
        WPStyleGuide.configureTableViewAppearance()
        WPStyleGuide.configureDefaultTint()
        WPStyleGuide.configureLightNavigationBarAppearance()
        WPStyleGuide.configureToolbarAppearance()

        UISegmentedControl.appearance().setTitleTextAttributes( [NSAttributedString.Key.font: WPStyleGuide.regularTextFont()], for: .normal)
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
        WPActionBar.appearance().barBackgroundColor = .basicBackground
        WPActionBar.appearance().lineColor = .basicBackground

        // Post Settings styles
        UITableView.appearance(whenContainedInInstancesOf: [AztecNavigationController.self]).tintColor = .editorPrimary
        UISwitch.appearance(whenContainedInInstancesOf: [AztecNavigationController.self]).onTintColor = .editorPrimary

        /// Sets the `tintColor` for parent category selection within the Post Settings screen
        UIView.appearance(whenContainedInInstancesOf: [PostCategoriesViewController.self]).tintColor = .editorPrimary

        /// It's necessary to target `PostCategoriesViewController` a second time to "reset" the UI element's `tintColor` for use in the app's Site Settings screen.
        UIView.appearance(whenContainedInInstancesOf: [PostCategoriesViewController.self, WPSplitViewController.self]).tintColor = .primary

    }
}

// MARK: - Apple Account Handling

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
                                             andServiceName: WPAppleIDKeychainServiceName)
        } catch let error as NSError {
            if error.code != errSecItemNotFound {
                DDLogError("Error while removing Apple User ID from keychain: \(error.localizedDescription)")
            }
        }
    }

}
