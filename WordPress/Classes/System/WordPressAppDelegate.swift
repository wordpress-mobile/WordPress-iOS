import UIKit
import Reachability
import WordPressShared
import ZendeskCoreSDK

class WordPressAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    @objc var logger: WPLogger!
    var analytics: WPAppAnalytics!
    var crashlytics: WPCrashlytics!
    var hockey: HockeyManager!
    @objc var internetReachability: Reachability!
    var authManager: WordPressAuthenticationManager!
    @objc var connectionAvailable: Bool = true

    private var pingHubManager: PingHubManager!
    private lazy var shortcutCreator = WP3DTouchShortcutCreator()
    private var noticePresenter: NoticePresenter!
    private var bgTask: UIBackgroundTaskIdentifier? = nil

    private var shouldRestoreApplicationState = false

    @objc class var shared: WordPressAppDelegate? {
        return UIApplication.shared.delegate as? WordPressAppDelegate
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        WordPressAppDelegate.fixKeychainAccess()

        configureWordPressAuthenticator()

        configureReachability()
        configureSelfHostedChallengeHandler()

        window?.makeKeyAndVisible()

        let solver = WPAuthTokenIssueSolver()
        let isFixingAuthTokenIssue = solver.fixAuthTokenIssueAndDo { [weak self] in
            self?.runStartupSequence(with: launchOptions ?? [:])
        }

        shouldRestoreApplicationState = !isFixingAuthTokenIssue

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DDLogInfo("didFinishLaunchingWithOptions state: \(application.applicationState)")

        InteractiveNotificationsManager.shared.registerForUserNotifications()
        showWelcomeScreenIfNeeded(animated: false)
        setupPingHub()
        setupBackgroundRefresh(application)
        setupComponentsAppearance()
        disableAnimationsForUITests(application)

        if FeatureFlag.quickStartV2.enabled {
            PushNotificationsManager.shared.deletePendingLocalNotifications()
        }

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
    }

    func applicationWillResignActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("\(self) \(#function)")
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

    @objc func runStartupSequence(with launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]) {
        // Local notifications
        addNotificationObservers()

        logger = WPLogger()
        configureHockeySDK()
        configureCrashlytics()
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
        DispatchQueue.global(qos: .background).async {
            MediaCoordinator.shared.refreshMediaStatus()
            PostCoordinator.shared.refreshPostStatus()
            MediaFileManager.clearUnusedMediaUploadFiles(onCompletion: nil, onError: nil)
        }

        setupWordPressExtensions()

        shortcutCreator.createShortcutsIf3DTouchAvailable(AccountHelper.isLoggedIn)

        window?.rootViewController = WPTabBarController.sharedInstance()

        setupNoticePresenter()
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
    /// XCUIApplication().launchArguments = ["NoAnimations"]
    ///
    private func disableAnimationsForUITests(_ application: UIApplication) {
        if CommandLine.arguments.contains("NoAnimations") {
            UIView.setAnimationsEnabled(false)
            application.windows.first?.layer.speed = MAXFLOAT
            application.keyWindow?.layer.speed = MAXFLOAT
        }
    }

    var runningInBackground: Bool {
        return UIApplication.shared.applicationState == .background
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

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
