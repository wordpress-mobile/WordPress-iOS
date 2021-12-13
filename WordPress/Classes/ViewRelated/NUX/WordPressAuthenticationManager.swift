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

    init(windowManager: WindowManager,
         authenticationHandler: AuthenticationHandler? = nil,
         quickStartSettings: QuickStartSettings = QuickStartSettings(),
         recentSiteService: RecentSitesService = RecentSitesService()) {
        self.windowManager = windowManager
        self.authenticationHandler = authenticationHandler
        self.quickStartSettings = quickStartSettings
        self.recentSiteService = recentSiteService
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
        let enableSignInWithApple = AppConfiguration.allowSignUp && !(BuildConfiguration.current ~= [.a8cBranchTest, .a8cPrereleaseTesting])

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
                                                   enableUnifiedCarousel: FeatureFlag.unifiedPrologueCarousel.enabled)
    }

    private func authenticatorStyle() -> WordPressAuthenticatorStyle {
        let prologueVC: UIViewController? = {
            guard let viewController = authenticationHandler?.prologueViewController else {
                return FeatureFlag.unifiedPrologueCarousel.enabled ? UnifiedPrologueViewController() : nil
            }

            return viewController
        }()

        let statusBarStyle: UIStatusBarStyle = {
            guard let statusBarStyle = authenticationHandler?.statusBarStyle else {
                return FeatureFlag.unifiedPrologueCarousel.enabled ? .default : .lightContent
            }

            return statusBarStyle
        }()

        let buttonViewTopShadowImage: UIImage? = {
            guard let image = authenticationHandler?.buttonViewTopShadowImage else {
                return UIImage(named: "darkgrey-shadow")
            }

            return image
        }()

        let prologuePrimaryButtonStyle = authenticationHandler?.prologuePrimaryButtonStyle
        let prologueSecondaryButtonStyle = authenticationHandler?.prologueSecondaryButtonStyle

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
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()

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
        let blogService = BlogService(managedObjectContext: context)

        return AccountHelper.isDotcomAvailable() || blogService.blogCountForAllAccounts() > 0
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
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        return accountService.defaultWordPressComAccount() == nil
    }

    /// Returns an instance of a SupportView, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
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

    /// Presents Support new request, with the specified ViewController as a source.
    /// Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: sourceViewController, with: sourceTag)
    }

    /// A self-hosted site URL is available and needs validated
    /// before presenting the username and password view controller.
    /// - Parameters:
    ///     - site: passes in the site information to the delegate method.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {
        if let authenticationHandler = authenticationHandler {
            authenticationHandler.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: onCompletion)
            return
        }

        let result: WordPressAuthenticatorResult = .presentPasswordController(value: true)
        onCompletion(result)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {
        if let authenticationHandler = authenticationHandler,
           authenticationHandler.presentLoginEpilogue(in: navigationController, for: credentials, windowManager: windowManager, onDismiss: onDismiss) {
            return
        }

        let onDismissQuickStartPrompt: (Blog, Bool) -> Void = { [weak self] blog, _ in
            self?.onDismissQuickStartPrompt(for: blog, onDismiss: onDismiss)
        }

        // If adding a self-hosted site, skip the Epilogue
        if let wporg = credentials.wporg,
           let blog = Blog.lookup(username: wporg.username, xmlrpc: wporg.xmlrpc, in: ContextManager.shared.mainContext) {
            presentQuickStartPrompt(for: blog, in: navigationController, onDismiss: onDismissQuickStartPrompt)
            return
        }

        if PostSignUpInterstitialViewController.shouldDisplay() {
            self.presentPostSignUpInterstitial(in: navigationController, onDismiss: onDismiss)
            return
        }

        //Present the epilogue view
        let storyboard = UIStoryboard(name: "LoginEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? LoginEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.credentials = credentials

        epilogueViewController.onBlogSelected = { [weak self] blog in
            guard let self = self else {
                return
            }

            self.recentSiteService.touch(blog: blog)

            guard self.quickStartSettings.isQuickStartAvailable(for: blog) else {
                if self.windowManager.isShowingFullscreenSignIn {
                    self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
                } else {
                    self.windowManager.showAppUI(for: blog)
                }
                return
            }

            self.presentQuickStartPrompt(for: blog, in: navigationController, onDismiss: onDismissQuickStartPrompt)
        }

        epilogueViewController.onCreateNewSite = {
            let wizardLauncher = SiteCreationWizardLauncher(onDismiss: onDismissQuickStartPrompt)
            guard let wizard = wizardLauncher.ui else {
                return
            }

            navigationController.present(wizard, animated: true)
            WPAnalytics.track(.enhancedSiteCreationAccessed, withProperties: ["source": "login_epilogue"])
        }

        navigationController.pushViewController(epilogueViewController, animated: true)
    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
        let storyboard = UIStoryboard(name: "SignupEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? SignupEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.credentials = credentials
        epilogueViewController.socialService = service
        epilogueViewController.onContinue = { [weak self] in
            guard let self = self else {
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

            UserDefaults.standard.set(false, forKey: UserDefaults.standard.welcomeNotificationSeenKey)
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

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let numberOfBlogs = service.defaultWordPressComAccount()?.blogs?.count ?? 0

        return numberOfBlogs > 0
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
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        let account = service.createOrUpdateAccount(withUsername: username, authToken: authToken)
        if service.defaultWordPressComAccount() == nil {
            service.setDefaultWordPressComAccount(account)
        }
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

// MARK: - Quick Start Prompt
private extension WordPressAuthenticationManager {
    func presentQuickStartPrompt(for blog: Blog, in navigationController: UINavigationController, onDismiss: ((Blog, Bool) -> Void)?) {
        // If the quick start prompt has already been dismissed,
        // then show the My Site screen for the specified blog
        guard !quickStartSettings.promptWasDismissed(for: blog) else {

            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                navigationController.dismiss(animated: true)
            }

            return
        }

        // Otherwise, show the Quick Start prompt
        let quickstartPrompt = QuickStartPromptViewController(blog: blog)
        quickstartPrompt.onDismiss = onDismiss
        navigationController.pushViewController(quickstartPrompt, animated: true)
    }

    func onDismissQuickStartPrompt(for blog: Blog, onDismiss: @escaping () -> Void) {
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
            QuickStartTourGuide.shared.setupWithDelay(for: blog)
        })
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

        viewController.dismiss = { dismissAction in
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

        service.syncWPCom(authToken: authToken, isJetpackLogin: isJetpackLogin, onSuccess: { account in

            /// HACK: An alternative notification to LoginFinished. Observe this instead of `WPSigninDidFinishNotification` for Jetpack logins.
            /// When WPTabViewController no longer destroy's and rebuilds the view hierarchy this alternate notification can be removed.
            ///
            let notification = isJetpackLogin == true ? .wordpressLoginFinishedJetpackLogin : Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification)
            NotificationCenter.default.post(name: notification, object: account)

            onCompletion()

        }, onFailure: { _ in
            onCompletion()
        })
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
