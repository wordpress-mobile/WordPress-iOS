import Foundation
import WordPressAuthenticator
import Gridicons
import UIKit


// MARK: - WordPressAuthenticationManager
//
@objc
class WordPressAuthenticationManager: NSObject {
    static var isPresentingSignIn = false
    private let windowManager: WindowManager

    /// Allows overriding some WordPressAuthenticator delegate methods
    /// without having to reimplement WordPressAuthenticatorDelegate
    private let authenticationHandler: AuthenticationHandler?

    private let quickStartSettings: QuickStartSettings

    private let recentSiteService: RecentSitesService

    private let remoteFeaturesStore: RemoteFeatureFlagStore

    init(windowManager: WindowManager,
         authenticationHandler: AuthenticationHandler? = nil,
         quickStartSettings: QuickStartSettings = QuickStartSettings(),
         recentSiteService: RecentSitesService = RecentSitesService(),
         remoteFeaturesStore: RemoteFeatureFlagStore) {
        self.windowManager = windowManager
        self.authenticationHandler = authenticationHandler
        self.quickStartSettings = quickStartSettings
        self.recentSiteService = recentSiteService
        self.remoteFeaturesStore = remoteFeaturesStore
    }

    /// Support is only available to the WordPress iOS App. Our Authentication Framework doesn't have direct access.
    /// We'll setup a mechanism to relay the Support event back to the Authenticator.
    ///
    func startRelayingSupportNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationReceived), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationCleared), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }
}

// MARK: - Initialization Methods
//
extension WordPressAuthenticationManager {
    /// Initializes WordPressAuthenticator with all of the parameters that will be needed during the login flow.
    ///
    func initializeWordPressAuthenticator() {
        let displayStrings = WordPressAuthenticatorDisplayStrings(
            continueWithWPButtonTitle: AppConstants.Login.continueButtonTitle
        )

        WordPressAuthenticator.initialize(configuration: authenticatorConfiguation(),
                                          style: authenticatorStyle(),
                                          unifiedStyle: unifiedStyle(),
                                          displayStrings: displayStrings)
    }

    private func authenticatorConfiguation() -> WordPressAuthenticatorConfiguration {
        // SIWA can not be enabled for internal builds
        // Ref https://github.com/wordpress-mobile/WordPress-iOS/pull/12332#issuecomment-521994963
        let enableSignInWithApple = !(BuildConfiguration.current ~= [.a8cBranchTest, .a8cPrereleaseTesting])

        return WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.client,
                                                   wpcomSecret: ApiCredentials.secret,
                                                   wpcomScheme: WPComScheme,
                                                   wpcomTermsOfServiceURL: WPAutomatticTermsOfServiceURL,
                                                   wpcomBaseURL: WordPressComOAuthClient.WordPressComOAuthDefaultBaseUrl,
                                                   wpcomAPIBaseURL: Environment.current.wordPressComApiBase,
                                                   googleLoginClientId: ApiCredentials.googleLoginClientId,
                                                   googleLoginServerClientId: ApiCredentials.googleLoginServerClientId,
                                                   googleLoginScheme: ApiCredentials.googleLoginSchemeId,
                                                   userAgent: WPUserAgent.wordPress(),
                                                   showLoginOptions: true,
                                                   enableSignUp: AppConfiguration.allowSignUp,
                                                   enableSignInWithApple: enableSignInWithApple,
                                                   enableSignupWithGoogle: AppConfiguration.allowSignUp,
                                                   enableUnifiedAuth: true,
                                                   enableUnifiedCarousel: true,
                                                   enablePasskeys: true,
                                                   enableSocialLogin: true)
    }

    private func authenticatorStyle() -> WordPressAuthenticatorStyle {
        let prologueVC: UIViewController? = {
            guard let viewController = authenticationHandler?.prologueViewController else {
                return SplashPrologueViewController()
            }

            return viewController
        }()

        let statusBarStyle: UIStatusBarStyle = {
            guard let statusBarStyle = authenticationHandler?.statusBarStyle else {
                return .default
            }

            return statusBarStyle
        }()

        let buttonViewTopShadowImage: UIImage? = {
            guard let image = authenticationHandler?.buttonViewTopShadowImage else {
                return UIImage(named: "darkgrey-shadow")
            }

            return image
        }()

        var prologuePrimaryButtonStyle: NUXButtonStyle?
        var prologueSecondaryButtonStyle: NUXButtonStyle?

        if AppConfiguration.isWordPress {
            prologuePrimaryButtonStyle = SplashPrologueStyleGuide.primaryButtonStyle
            prologueSecondaryButtonStyle = SplashPrologueStyleGuide.secondaryButtonStyle
        } else {
            prologuePrimaryButtonStyle = authenticationHandler?.prologuePrimaryButtonStyle
            prologueSecondaryButtonStyle = authenticationHandler?.prologueSecondaryButtonStyle
        }

        return WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .primaryButtonBackground,
                                           primaryNormalBorderColor: nil,
                                           primaryHighlightBackgroundColor: .primaryButtonDownBackground,
                                           primaryHighlightBorderColor: nil,
                                           secondaryNormalBackgroundColor: .authSecondaryButtonBackground,
                                           secondaryNormalBorderColor: .secondaryButtonBorder,
                                           secondaryHighlightBackgroundColor: .secondaryButtonDownBackground,
                                           secondaryHighlightBorderColor: .secondaryButtonDownBorder,
                                           disabledBackgroundColor: .textInverted,
                                           disabledBorderColor: .neutral(.shade10),
                                           primaryTitleColor: .white,
                                           secondaryTitleColor: .text,
                                           disabledTitleColor: .neutral(.shade20),
                                           disabledButtonActivityIndicatorColor: .text,
                                           textButtonColor: .primary,
                                           textButtonHighlightColor: .primaryDark,
                                           instructionColor: .text,
                                           subheadlineColor: .textSubtle,
                                           placeholderColor: .textPlaceholder,
                                           viewControllerBackgroundColor: .listBackground,
                                           textFieldBackgroundColor: .listForeground,
                                           buttonViewBackgroundColor: .authButtonViewBackground,
                                           buttonViewTopShadowImage: buttonViewTopShadowImage,
                                           navBarImage: .gridicon(.mySites),
                                           navBarBadgeColor: .accent(.shade20),
                                           navBarBackgroundColor: .appBarBackground,
                                           prologueBackgroundColor: .primary,
                                           prologueTitleColor: .textInverted,
                                           prologuePrimaryButtonStyle: prologuePrimaryButtonStyle,
                                           prologueSecondaryButtonStyle: prologueSecondaryButtonStyle,
                                           prologueTopContainerChildViewController: prologueVC,
                                           statusBarStyle: statusBarStyle)
    }

    private func unifiedStyle() -> WordPressAuthenticatorUnifiedStyle {
        let prologueButtonsBackgroundColor: UIColor = {
            guard let color = authenticationHandler?.prologueButtonsBackgroundColor else {
                return .clear
            }

            return color
        }()


        /// Uses the same prologueButtonsBackgroundColor but we need to be able to return nil
        let prologueViewBackgroundColor: UIColor? = authenticationHandler?.prologueButtonsBackgroundColor

        return WordPressAuthenticatorUnifiedStyle(borderColor: .divider,
                                                  errorColor: .error,
                                                  textColor: .text,
                                                  textSubtleColor: .textSubtle,
                                                  textButtonColor: .primary,
                                                  textButtonHighlightColor: .primaryDark,
                                                  viewControllerBackgroundColor: .basicBackground,
                                                  prologueButtonsBackgroundColor: prologueButtonsBackgroundColor,
                                                  prologueViewBackgroundColor: prologueViewBackgroundColor,
                                                  prologueBackgroundImage: authenticationHandler?.prologueBackgroundImage,
                                                  prologueButtonsBlurEffect: nil,
                                                  navBarBackgroundColor: .appBarBackground,
                                                  navButtonTextColor: .appBarTint,
                                                  navTitleTextColor: .appBarText)
    }
}


// MARK: - Static Methods
//
extension WordPressAuthenticationManager {

    /// Returns an Authentication ViewController (configured to allow only WordPress.com). This method pre-populates the Email + Username
    /// with the values returned by the default WordPress.com account (if any).
    ///
    /// - Parameter onDismissed: Closure to be executed whenever the returned ViewController is dismissed.
    ///
    @objc
    class func signinForWPComFixingAuthToken(_ onDismissed: ((_ cancelled: Bool) -> Void)? = nil) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)

        return WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: account?.email, dotcomUsername: account?.username, onDismissed: onDismissed)
    }

    /// Presents the WordPress Authentication UI from the rootViewController (configured to allow only WordPress.com).
    /// This method pre-populates the Email + Username with the values returned by the default WordPress.com account (if any).
    ///
    @objc
    class func showSigninForWPComFixingAuthToken() {
        guard let presenter = UIApplication.shared.mainWindow?.rootViewController else {
            assertionFailure()
            return
        }

        guard !isPresentingSignIn else {
            return
        }

        isPresentingSignIn = true
        let controller = signinForWPComFixingAuthToken({ (_) in
            isPresentingSignIn = false
        })
        presenter.present(controller, animated: true)
    }
}


// MARK: - Notification Handlers
//
extension WordPressAuthenticationManager {

    @objc func supportPushNotificationReceived(_ notification: Foundation.Notification) {
        WordPressAuthenticator.shared.supportPushNotificationReceived()
    }

    @objc func supportPushNotificationCleared(_ notification: Foundation.Notification) {
        WordPressAuthenticator.shared.supportPushNotificationCleared()
    }

}


// MARK: - WordPressAuthenticator Delegate
//
extension WordPressAuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates if the active Authenticator can be dismissed, or not. Authentication is Dismissable when there is a
    /// default wpcom account, or at least one self-hosted blog.
    ///
    var dismissActionEnabled: Bool {
        let context = ContextManager.sharedInstance().mainContext

        return AccountHelper.isDotcomAvailable() || Blog.count(in: context) > 0
    }

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Indicates whether a link to WP.com TOS should be available, or not.
    ///
    var wpcomTermsOfServiceEnabled: Bool {
        return true
    }

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        return ZendeskUtils.zendeskEnabled
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        return ZendeskUtils.showSupportNotificationIndicator
    }

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    /// We allow to connect with WordPress.com account only if there is no default account connected already.
    var allowWPComLogin: Bool {
        (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)) == nil
    }

    /// Returns an instance of a SupportView, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag,
                        lastStep: AuthenticatorAnalyticsTracker.Step,
                        lastFlow: AuthenticatorAnalyticsTracker.Flow) {
        presentSupport(from: sourceViewController, sourceTag: sourceTag)
    }

    /// Presents Support new request, with the specified ViewController as a source.
    /// Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        presentSupport(from: sourceViewController, sourceTag: sourceTag)
    }

    /// A self-hosted site URL is available and needs validated
    /// before presenting the username and password view controller.
    /// - Parameters:
    ///     - site: passes in the site information to the delegate method.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {

        let result: WordPressAuthenticatorResult = .presentPasswordController(value: true)
        onCompletion(result)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, source: SignInSource?, onDismiss: @escaping () -> Void) {

        // If adding a self-hosted site, skip the Epilogue
        if let wporg = credentials.wporg,
           let blog = Blog.lookup(username: wporg.username, xmlrpc: wporg.xmlrpc, in: ContextManager.shared.mainContext) {

            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                navigationController.dismiss(animated: true)
            }

            return
        }

        if PostSignUpInterstitialViewController.shouldDisplay() {
            self.presentPostSignUpInterstitial(in: navigationController, onDismiss: onDismiss)
            return
        }

        // Present the epilogue view
        let storyboard = UIStoryboard(name: "LoginEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? LoginEpilogueViewController else {
            fatalError()
        }

        let onBlogSelected: ((Blog) -> Void) = { [weak self, weak navigationController] blog in
            guard let self, let navigationController else {
                return
            }

            // If the user just signed in, refresh the A/B assignments
            ABTest.start()

            self.recentSiteService.touch(blog: blog)
            self.presentOnboardingQuestionsPrompt(in: navigationController, blog: blog, onDismiss: onDismiss)
        }

        // If the user has only 1 blog, skip the site selector and go right to the next step
        if numberOfBlogs() == 1, let firstBlog = firstBlog() {
            onBlogSelected(firstBlog)
            return
        }

        epilogueViewController.credentials = credentials
        epilogueViewController.onBlogSelected = onBlogSelected

        let onDismissQuickStartPromptForNewSiteHandler = onDismissQuickStartPromptHandler(type: .newSite, onDismiss: onDismiss)

        epilogueViewController.onCreateNewSite = { [weak navigationController] in
            guard let navigationController else { return }

            let source = "login_epilogue"
            JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: navigationController, source: source, onDidDismiss: {
                guard JetpackFeaturesRemovalCoordinator.siteCreationPhase(blog: self.firstBlog()) != .two else {
                    return
                }

                // Display site creation flow if not in phase two
                let wizardLauncher = SiteCreationWizardLauncher(onDismiss: onDismissQuickStartPromptForNewSiteHandler)
                guard let wizard = wizardLauncher.ui else {
                    return
                }

                navigationController.present(wizard, animated: true)
                SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: source)
            })
        }

        navigationController.delegate = epilogueViewController
        navigationController.pushViewController(epilogueViewController, animated: true)

    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, socialUser: SocialUser?) {

        let storyboard = UIStoryboard(name: "SignupEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? SignupEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.credentials = credentials
        epilogueViewController.socialUser = socialUser
        epilogueViewController.onContinue = { [weak self, weak navigationController] in
            guard let self, let navigationController else {
                return
            }

            if PostSignUpInterstitialViewController.shouldDisplay() {
                self.presentPostSignUpInterstitial(in: navigationController)
            } else {
                if self.windowManager.isShowingFullscreenSignIn {
                    self.windowManager.dismissFullscreenSignIn()
                } else {
                    navigationController.dismiss(animated: true)
                }
            }

            UserPersistentStoreFactory.instance().set(false, forKey: UserPersistentStoreFactory.instance().welcomeNotificationSeenKey)
        }

        navigationController.pushViewController(epilogueViewController, animated: true)
    }

    /// Indicates if the Login Epilogue should be presented. This is false only when we're doing a Jetpack Connect, and the new
    /// WordPress.com account has no sites. Capicci?
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        guard isJetpackLogin else {
            return true
        }

        return numberOfBlogs() > 0
    }

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        return true
    }

    /// Whenever a WordPress.com account has been created during the Auth flow, we'll add a new local WPCOM Account, and set it as
    /// the new DefaultWordPressComAccount.
    ///
    func createdWordPressComAccount(username: String, authToken: String) {
        let service = AccountService(coreDataStack: ContextManager.sharedInstance())
        let context = ContextManager.sharedInstance().mainContext
        let accountID = service.createOrUpdateAccount(withUsername: username, authToken: authToken)
        guard let account = try? context.existingObject(with: accountID) as? WPAccount else {
            DDLogError("Failed to find the account")
            return
        }
        service.setDefaultWordPressComAccount(account)
    }

    /// When an Apple account is used during the Auth flow, save the Apple user id to the keychain.
    /// It will be used on app launch to check the user id state.
    ///
    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPAppleIDKeychainUsernameKey,
                                                andPassword: appleUserID,
                                                forServiceName: WPAppleIDKeychainServiceName,
                                                updateExisting: true)
        } catch {
            DDLogInfo("Error while saving Apple User ID: \(error)")
        }
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        if let wpcom = credentials.wpcom {
            syncWPCom(authToken: wpcom.authToken, isJetpackLogin: wpcom.isJetpackLogin, onCompletion: onCompletion)
        } else if let wporg = credentials.wporg {
            syncWPOrg(username: wporg.username, password: wporg.password, xmlrpc: wporg.xmlrpc, options: wporg.options, onCompletion: onCompletion)
        }
    }

    /// Indicates if the given Auth error should be handled by the host app.
    ///
    func shouldHandleError(_ error: Error) -> Bool {
        // Here for protocol compliance.
        return false
    }

    /// Handles the given error.
    /// Called if `shouldHandleError` is true.
    ///
    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {
        // Here for protocol compliance.
        let vc = UIViewController()
        onCompletion(vc)
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {
        WPAppAnalytics.track(event)
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        WPAppAnalytics.track(event, withProperties: properties)
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        WPAppAnalytics.track(event, error: error)
    }
}

// MARK: - Blog Count Helpers
private extension WordPressAuthenticationManager {
    private func numberOfBlogs() -> Int {
        let context = ContextManager.sharedInstance().mainContext
        let numberOfBlogs = (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.blogs?.count ?? 0

        return numberOfBlogs
    }

    private func firstBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        return try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.blogs?.first
    }
}

// MARK: - Onboarding Questions Prompt
private extension WordPressAuthenticationManager {
    private func presentOnboardingQuestionsPrompt(in navigationController: UINavigationController, blog: Blog, onDismiss: (() -> Void)? = nil) {
        let windowManager = self.windowManager

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                self.windowManager.showAppUI(for: blog)
            }
            return
        }

        let coordinator = OnboardingQuestionsCoordinator()
        coordinator.navigationController = navigationController

        let viewController = OnboardingQuestionsPromptViewController(with: coordinator)

        coordinator.onDismiss = { [weak navigationController] selectedOption in
            guard let navigationController else { return }

            self.handleOnboardingQuestionsWillDismiss(option: selectedOption)

            let completion: (() -> Void)? = {
                let userInfo = ["option": selectedOption]
                NotificationCenter.default.post(name: .onboardingPromptWasDismissed, object: nil, userInfo: userInfo)
            }

            if windowManager.isShowingFullscreenSignIn {
                windowManager.dismissFullscreenSignIn(completion: completion)
            } else {
                navigationController.dismiss(animated: true, completion: completion)
            }

            onDismiss?()
        }

        navigationController.pushViewController(viewController, animated: true)
    }


    /// To prevent a weird jump from the MySite tab to the reader/notifications tab
    /// We'll pre-switch to the users selected tab before the login flow dismisses
    private func handleOnboardingQuestionsWillDismiss(option: OnboardingOption) {
        if option == .reader {
            RootViewCoordinator.sharedPresenter.showReaderTab()
        } else if option == .notifications {
            RootViewCoordinator.sharedPresenter.showNotificationsTab()
        }
    }


}

// MARK: - Quick Start Prompt
private extension WordPressAuthenticationManager {

    typealias QuickStartOnDismissHandler = (Blog, Bool) -> Void

    func onDismissQuickStartPromptHandler(type: QuickStartType, onDismiss: @escaping () -> Void) -> QuickStartOnDismissHandler {
        return { [weak self] blog, _ in
            guard let self = self else {
                // If self is nil the user will be stuck on the login and not able to progress
                // Trigger a fatal so we can track this better in Sentry.
                // This case should be very rare.
                fatalError("Could not get a reference to self when selecting the blog on the login epilogue")
            }

            onDismiss()

            // If the quick start prompt has already been dismissed,
            // then show the My Site screen for the specified blog
            guard !self.quickStartSettings.promptWasDismissed(for: blog) else {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
                return
            }

            // Otherwise, show the My Site screen for the specified blog and after a short delay,
            // trigger the Quick Start tour
            self.windowManager.showAppUI(for: blog, completion: {
                QuickStartTourGuide.shared.setupWithDelay(for: blog, type: type)
            })
        }
    }
}


// MARK: - WordPressAuthenticatorManager
//
private extension WordPressAuthenticationManager {
    /// Displays the post sign up interstitial if needed, if it's not displayed
    private func presentPostSignUpInterstitial(
        in navigationController: UINavigationController,
        onDismiss: (() -> Void)? = nil) {

        let viewController = PostSignUpInterstitialViewController()
        let windowManager = self.windowManager

        viewController.dismiss = { [weak navigationController] dismissAction in
            guard let navigationController else { return }

            let completion: (() -> Void)?

            switch dismissAction {
            case .none:
                completion = nil
            case .addSelfHosted:
                completion = {
                    NotificationCenter.default.post(name: .addSelfHosted, object: nil)
                }
            case .createSite:
                completion = {
                    NotificationCenter.default.post(name: .createSite, object: nil)
                }
            }

            if windowManager.isShowingFullscreenSignIn {
                windowManager.dismissFullscreenSignIn(completion: completion)
            } else {
                navigationController.dismiss(animated: true, completion: completion)
            }

            onDismiss?()
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    /// Synchronizes a WordPress.com account with the specified credentials.
    ///
    private func syncWPCom(authToken: String, isJetpackLogin: Bool, onCompletion: @escaping () -> ()) {
        let service = WordPressComSyncService()

        // Create a dispatch group to wait for both API calls.
        let syncGroup = DispatchGroup()

        // Sync account and blog
        syncGroup.enter()
        service.syncWPCom(authToken: authToken, isJetpackLogin: isJetpackLogin, onSuccess: { account in

            /// HACK: An alternative notification to LoginFinished. Observe this instead of `WPSigninDidFinishNotification` for Jetpack logins.
            /// When WPTabViewController no longer destroy's and rebuilds the view hierarchy this alternate notification can be removed.
            ///
            let notification = isJetpackLogin == true ? .wordpressLoginFinishedJetpackLogin : Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification)
            NotificationCenter.default.post(name: notification, object: account)

            syncGroup.leave()
        }, onFailure: { _ in
            syncGroup.leave()
        })

        // Refresh Remote Feature Flags
        syncGroup.enter()
        WordPressAppDelegate.shared?.updateFeatureFlags(authToken: authToken, completion: {
            syncGroup.leave()
        })

        // Sync done
        syncGroup.notify(queue: .main) {
            onCompletion()
        }
    }

    /// Synchronizes a WordPress.org account with the specified credentials.
    ///
    private func syncWPOrg(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any], onCompletion: @escaping () -> ()) {
        let service = BlogSyncFacade()

        service.syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { blog in
            RecentSitesService().touch(blog: blog)
            onCompletion()
        }
    }
}

// MARK: - Support Helper
//
private extension WordPressAuthenticationManager {
    /// Presents the support screen which displays different support options depending on whether this is the WordPress app or the Jetpack app.
    private func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        // Reset the nav style so the Support nav bar has the WP style, not the Auth style.
        WPStyleGuide.configureNavigationAppearance()

        // Since we're presenting the support VC as a form sheet, the parent VC's viewDidAppear isn't called
        // when this VC is dismissed.  This means the tracking step isn't reset properly, so we'll need to do
        // it here manually before tracking the new step.
        let step = tracker.state.lastStep

        tracker.track(step: .help)

        let controller = SupportTableViewController { [weak self] in
            self?.tracker.track(click: .dismiss)
            self?.tracker.set(step: step)
        }
        controller.sourceTag = sourceTag

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true)
    }
}
