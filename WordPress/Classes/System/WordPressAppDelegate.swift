import SFHFKeychainUtils
import UIKit
import BuildSettingsKit
import CocoaLumberjackSwift
import ShareExtensionCore
import Reachability
import AutomatticTracks
import AutomatticEncryptedLogs
import WordPressAuthenticator
import WordPressShared
import AsyncImageKit
import AutomatticAbout
import UIDeviceIdentifier
import SVProgressHUD
import WordPressUI
import ZendeskCoreSDK

public class WordPressAppDelegate: UIResponder, UIApplicationDelegate {

    public var window: UIWindow?

    let backgroundTasksCoordinator = BackgroundTasksCoordinator(tasks: [
        WeeklyRoundupBackgroundTask()
    ], eventHandler: WordPressBackgroundTaskEventHandler())

    @objc
    lazy var windowManager: WindowManager = {
        guard let window else {
            fatalError("The App cannot run without a window.")
        }
        return switch BuildSettings.current.brand {
        case .wordpress: WindowManager(window: window)
        case .jetpack: JetpackWindowManager(window: window)
        }
    }()

    var analytics: WPAppAnalytics?

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

    private let loggingStack = WPLoggingStack.shared

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

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        AssertionLoggerDependencyContainer.logger = AssertionLogger()
        UITestConfigurator.prepareApplicationForUITests(in: application, window: window)

        AppAppearance.overrideAppearance()
        MemoryCache.shared.register()
        MediaImageService.migrateCacheIfNeeded()
        PostCoordinator.shared.delegate = self

        // Start CrashLogging as soon as possible (in case a crash happens during startup)
        try? loggingStack.start()

        // Configure WPCom API overrides
        configureWordPressComApi()

        configureWordPressAuthenticator()

        ReachabilityUtils.configure()

        configureSelfHostedChallengeHandler()
        updateFeatureFlags()
        updateRemoteConfig()

        window.makeKeyAndVisible()

        // Restore a disassociated account prior to fixing tokens.
        AccountService(coreDataStack: ContextManager.shared).restoreDisassociatedAccountIfNecessary()

        customizeAppearance()
        configureAnalytics()

        let solver = WPAuthTokenIssueSolver()
        _ = solver.fixAuthTokenIssueAndDo { [weak self] in
            self?.runStartupSequence(with: launchOptions ?? [:])
        }

        return true
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DDLogInfo("didFinishLaunchingWithOptions state: \(application.applicationState)")

        ABTest.start()

        Media.removeTemporaryData()
        NSItemProvider.removeTemporaryData()
        InteractiveNotificationsManager.shared.registerForUserNotifications()
        setupPingHub()
        setupBackgroundRefresh(application)
        setupNoticePresenter()
        DebugMenuViewController.configure(in: window)
        AppTips.initialize()

        // This was necessary to properly load fonts for the Stories editor. I believe external libraries may require this call to access fonts.
        let fonts = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
        fonts?.forEach({ url in
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        })

        startObservingAppleIDCredentialRevoked()

        NotificationCenter.default.post(name: .applicationLaunchCompleted, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            WKWebView.warmup()
        }

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext) {
            BlogSyncFacade().syncBlogs(for: account, success: { /* Do nothing */ }, failure: { _ in /* Do nothing */ })
        }

        return true
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        analytics?.trackApplicationDidEnterBackground(screenName: currentlySelectedScreen)

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

        if let bgTask {
            DDLogInfo("BackgroundTask: beginBackgroundTask for bgTask = \(bgTask.rawValue)")
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        updateFeatureFlags()
        updateRemoteConfig()

        // JetpackWindowManager is only available in the Jetpack target.
        if let windowManager = windowManager as? JetpackWindowManager {
            windowManager.startMigrationFlowIfNeeded()
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")

        analytics?.trackApplicationDidBecomeActive()

        // This is done here so the check is done on app launch and app switching.
        checkAppleIDCredentialState()

        GutenbergSettings().performGutenbergPhase2MigrationIfNeeded()
    }

    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handler = WP3DTouchShortcutHandler()
        completionHandler(handler.handleShortcutItem(shortcutItem))
    }

    public func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // 21-Oct-2017: We are only handling background URLSessions initiated by the share extension so there
        // is no need to inspect the identifier beyond the simple check here.
        let appGroupName = BuildSettings.current.appGroupName
        if identifier.contains(appGroupName) {
            let manager = ShareExtensionSessionManager(appGroup: appGroupName, backgroundSessionIdentifier: identifier)
            manager.backgroundSessionCompletionBlock = completionHandler
            manager.startBackgroundSession()
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
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
    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
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

        configureAppRatingUtility()

        if UITestConfigurator.isEnabled(.disableLogging) {
            WordPressAppDelegate.setLogLevel(.off)
        } else {
            let libraryLogger = WordPressLibraryLogger()
            TracksLogging.delegate = libraryLogger
            WPKitSetLoggingDelegate(libraryLogger)
            WPAuthenticatorSetLoggingDelegate(libraryLogger)
            printDebugLaunchInfoWithLaunchOptions(launchOptions)
            toggleExtraDebuggingIfNeeded()
        }

#if DEBUG
        KeychainTools.processKeychainDebugArguments()

        // Zendesk Logging
        CoreLogger.enabled = true
        CoreLogger.logLevel = .debug
#endif

        ZendeskUtils.setup()

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
            MediaFileManager.clearUnusedMediaUploadFiles(onCompletion: nil, onError: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            PostCoordinator.shared.initializeSync()
        }

        setupWordPressExtensions()

        shortcutCreator.createShortcutsIf3DTouchAvailable(AccountHelper.isLoggedIn)

        AccountService.loadDefaultAccountCookies()

        windowManager.showUI()
        restoreAppState()
    }

    private func mergeDuplicateAccountsIfNeeded() {
        AccountService(coreDataStack: ContextManager.shared).mergeDuplicatesIfNecessary()
    }

    private func setupPingHub() {
        pingHubManager = PingHubManager()
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

    // MARK: - State Restoration

    private func restoreAppState() {
        if let viewController = EditPostViewController.restore() {
            window?.topmostPresentedViewController?.present(viewController, animated: false)
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
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationsManager.shared.registerDeviceToken(deviceToken)
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationsManager.shared.registrationDidFail(error as NSError)
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogInfo("\(self) \(#function)")
        PushNotificationsManager.shared.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }

}

// MARK: - Utility Configuration

extension WordPressAppDelegate {

    func configureAnalytics() {
        analytics = WPAppAnalytics()
    }

    func configureAppRatingUtility() {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return
        }

        let utility = AppRatingUtility.shared
        utility.systemWideSignificantEventCountRequiredForPrompt = 20
        utility.setVersion(version)
    }

    func configureSelfHostedChallengeHandler() {
        WordPressOrgXMLRPCApi.onChallenge = { (challenge, completionHandler) in
            guard let alertController = HTTPAuthenticationAlertController.controller(for: challenge, handler: completionHandler) else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            alertController.presentFromRootViewController()
        }
    }

    @objc func configureWordPressAuthenticator() {
        let isJetpack = BuildSettings.current.brand == .jetpack
        let authManager = WordPressAuthenticationManager(
            windowManager: windowManager,
            authenticationHandler: isJetpack ? JetpackAuthenticationManager() : nil,
            remoteFeaturesStore: RemoteFeatureFlagStore()
        )

        authManager.initializeWordPressAuthenticator()
        authManager.startRelayingSupportNotifications()

        WordPressAuthenticator.shared.delegate = authManager
        self.authManager = authManager
    }

    func presentDefaultAccountPrimarySite(from navigationController: UINavigationController) {
        self.authManager?.presentDefaultAccountPrimarySite(from: navigationController)
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

    @objc func configureWordPressComApi() {
        if let baseUrl = UserPersistentStoreFactory.instance().string(forKey: "wpcom-api-base-url"), let url = URL(string: baseUrl) {
            AppEnvironment.replaceEnvironment(wordPressComApiBase: url)
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
        case is MigrationNavigationController:
            return "Jetpack Migration View"
        case is MigrationLoadWordPressViewController:
            return "Jetpack Migration Load WordPress View"
        default:
            return RootViewCoordinator.sharedPresenter.currentlySelectedScreen()
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
        // Enable certain feature flags on test builds.
        if BuildConfiguration.current.isInternal {
            FeatureFlagOverrideStore().override(RemoteFeatureFlag.dotComWebLogin, withValue: true)
        }

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
        remoteConfigStore.update { [weak self] in
            self?.checkForAppUpdates()
        }
    }

    private func checkForAppUpdates() {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return wpAssertionFailure("No CFBundleShortVersionString found in Info.plist")
        }
        let coordinator = AppUpdateCoordinator(currentVersion: version)
        Task {
            await coordinator.checkForAppUpdates()
        }
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
        let udid = device.identifierForVendor?.uuidString ?? unknown

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
        CocoaLumberjackSwift.dynamicLogLevel = level
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
            clearReaderStuff()
        }

        toggleExtraDebuggingIfNeeded()

        WPAnalytics.track(.defaultAccountChanged)
    }

    @objc fileprivate func handleLowMemoryWarningNotification(_ notification: NSNotification) {
        WPAnalytics.track(.lowMemoryWarning)
    }

    private func clearReaderStuff() {
        ReaderPostService(coreDataStack: ContextManager.shared).deletePostsWithNoTopic()
        ReaderTopicService(coreDataStack: ContextManager.shared).deleteAllTopics()
        ReaderPostService(coreDataStack: ContextManager.shared).clearInUseFlags()
        ReaderTopicService(coreDataStack: ContextManager.shared).clearInUseFlags()
        ReaderPostService(coreDataStack: ContextManager.shared).clearSavedPostFlags()
        UserDefaults.standard.isReaderSelected = false
        UserDefaults.standard.readerSidebarSelection = nil
        UserDefaults.standard.readerSearchHistory = []
        UserDefaults.standard.readerDidSelectInterestsKey = false
    }
}

// MARK: - Extensions

extension WordPressAppDelegate {

    func setupWordPressExtensions() {
        let accountService = AccountService(coreDataStack: ContextManager.shared)
        accountService.setupAppExtensionsWithDefaultAccount()

        let maxImagesize = MediaSettings().maxImageSizeSetting
        ShareExtensionService().configureShareExtensionMaximumMediaDimension(maxImagesize)

        saveRecentSitesForExtensions()
    }

    // MARK: - Share Extension

    func setupShareExtensionToken() {

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext), let authToken = account.authToken {
            ShareExtensionService().configureShareExtensionToken(authToken)
            ShareExtensionService().configureShareExtensionUsername(account.username)
        }
    }

    func removeShareExtensionConfiguration() {
        ShareExtensionService().removeShareExtensionConfiguration()
    }

    @objc func saveRecentSitesForExtensions() {
        let recentSites = RecentSitesService().recentSites
        ShareExtensionService().configureShareExtensionRecentSites(recentSites)
    }

    // MARK: - Notification Service Extension

    func configureNotificationExtension() {

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext), let authToken = account.authToken, let userID = account.userID {
            let service = NotificationSupportService()
            service.insertServiceExtensionToken(authToken)
            service.insertServiceExtensionUsername(account.username)
            service.insertServiceExtensionUserID(userID.stringValue)
        }
    }

    func removeNotificationExtensionConfiguration() {
        let service = NotificationSupportService()
        service.deleteServiceExtensionToken()
        service.deleteServiceExtensionUsername()
        service.deleteServiceExtensionUserID()
    }
}

// MARK: - Appearance

extension WordPressAppDelegate {
    func customizeAppearance() {
        window?.backgroundColor = .black
        window?.tintColor = UIAppColor.primary

        WPStyleGuide.configureAppearance()

        SVProgressHUD.setBackgroundColor(UIAppColor.neutral(.shade70).withAlphaComponent(0.95))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setErrorImage(UIImage(named: "hud_error")!)
        SVProgressHUD.setSuccessImage(UIImage(named: "hud_success")!)
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
                if let error {
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

// MARK: - UI Test Support

extension WordPressAppDelegate {

    func autoSignInUITestSite() {
        guard let wpComSiteAddress = UserDefaults.standard.string(forKey: "ui-test-select-wpcom-site") else {
            return
        }

        let service = WordPressComSyncService()
        service.syncWPCom(authToken: "valid_token", isJetpackLogin: false, onSuccess: { account in
            if let blog = try? BlogQuery().hostname(containing: wpComSiteAddress).blog(in: ContextManager.shared.mainContext) {
                self.windowManager.showUI(for: blog)
            } else {
                fatalError("Can't find blog: \(wpComSiteAddress)")
            }
        }, onFailure: {
            fatalError("Can't sync blogs: \($0)")
        })
    }

}
