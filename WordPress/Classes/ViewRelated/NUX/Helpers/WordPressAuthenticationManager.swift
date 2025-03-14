import Foundation
import SFHFKeychainUtils
import WordPressAuthenticator
import WordPressShared
import Gridicons
import UIKit

// MARK: - WordPressAuthenticationManager
//
@objc
class WordPressAuthenticationManager: NSObject {
    static let WPSigninDidFinishNotification = WordPressAuthenticator.WPSigninDidFinishNotification

    static var isPresentingSignIn = false
    private let windowManager: WindowManager

    /// Allows overriding some WordPressAuthenticator delegate methods
    /// without having to reimplement WordPressAuthenticatorDelegate
    private let authenticationHandler: AuthenticationHandler?
    private let recentSiteService: RecentSitesService
    private let remoteFeaturesStore: RemoteFeatureFlagStore

    init(windowManager: WindowManager,
         authenticationHandler: AuthenticationHandler? = nil,
         recentSiteService: RecentSitesService = RecentSitesService(),
         remoteFeaturesStore: RemoteFeatureFlagStore) {
        self.windowManager = windowManager
        self.authenticationHandler = authenticationHandler
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
            continueWithWPButtonTitle: NSLocalizedString("Continue With WordPress.com", comment: "Button title. Takes the user to the login with WordPress.com flow.")
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

        return WordPressAuthenticatorConfiguration(
            wpcomClientId: ApiCredentials.client,
            wpcomSecret: ApiCredentials.secret,
            wpcomScheme: WPComScheme,
            wpcomTermsOfServiceURL: URL(string: WPAutomatticTermsOfServiceURL)!,
            wpcomBaseURL: WordPressComOAuthClient.WordPressComOAuthDefaultBaseURL,
            wpcomAPIBaseURL: AppEnvironment.current.wordPressComApiBase,
            googleLoginClientId: ApiCredentials.googleLoginClientId,
            googleLoginServerClientId: ApiCredentials.googleLoginServerClientId,
            googleLoginScheme: ApiCredentials.googleLoginSchemeId,
            userAgent: WPUserAgent.wordPress(),
            showLoginOptions: true,
            enableSignUp: FeatureFlag.signUp.enabled,
            enableSignInWithApple: enableSignInWithApple,
            enableSignupWithGoogle: FeatureFlag.signUp.enabled,
            enableUnifiedAuth: true,
            enableUnifiedCarousel: true,
            enablePasskeys: true,
            enableSocialLogin: true,
            disableAutofill: UITestConfigurator.isEnabled(.disableAutofill)
        )
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

        return WordPressAuthenticatorStyle(
            primaryNormalBackgroundColor: UIAppColor.primary,
            primaryNormalBorderColor: nil,
            primaryHighlightBackgroundColor: UIAppColor.primary(.shade80),
            primaryHighlightBorderColor: nil,
            secondaryNormalBackgroundColor: UIColor(light: .white, dark: .black),
            secondaryNormalBorderColor: .systemGray3,
            secondaryHighlightBackgroundColor: .systemGray3,
            secondaryHighlightBorderColor: .systemGray3,
            disabledBackgroundColor: .secondarySystemFill,
            disabledBorderColor: .secondarySystemFill,
            primaryTitleColor: .white,
            secondaryTitleColor: .label,
            disabledTitleColor: UIAppColor.neutral(.shade20),
            disabledButtonActivityIndicatorColor: .label,
            textButtonColor: UIAppColor.primary,
            textButtonHighlightColor: UIAppColor.primaryDark,
            instructionColor: .label,
            subheadlineColor: .secondaryLabel,
            placeholderColor: .tertiaryLabel,
            viewControllerBackgroundColor: .systemGroupedBackground,
            textFieldBackgroundColor: .secondarySystemGroupedBackground,
            buttonViewBackgroundColor: UIColor(light: .white, dark: .black),
            buttonViewTopShadowImage: buttonViewTopShadowImage,
            navBarImage: .gridicon(.mySites),
            navBarBadgeColor: UIAppColor.accent(.shade20),
            navBarBackgroundColor: .secondarySystemGroupedBackground,
            prologueBackgroundColor: UIAppColor.primary,
            prologueTitleColor: .label.variantInverted,
            prologuePrimaryButtonStyle: prologuePrimaryButtonStyle,
            prologueSecondaryButtonStyle: prologueSecondaryButtonStyle,
            prologueTopContainerChildViewController: prologueVC,
            statusBarStyle: statusBarStyle
        )
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

        return WordPressAuthenticatorUnifiedStyle(
            borderColor: .separator,
            errorColor: UIAppColor.error,
            textColor: .label,
            textSubtleColor: .secondaryLabel,
            textButtonColor: UIAppColor.primary,
            textButtonHighlightColor: UIAppColor.primaryDark,
            viewControllerBackgroundColor: .systemBackground,
            prologueButtonsBackgroundColor: prologueButtonsBackgroundColor,
            prologueViewBackgroundColor: prologueViewBackgroundColor,
            prologueBackgroundImage: authenticationHandler?.prologueBackgroundImage,
            prologueButtonsBlurEffect: nil,
            navBarBackgroundColor: .secondarySystemGroupedBackground,
            navButtonTextColor: .label,
            navTitleTextColor: .label
        )
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
        let context = ContextManager.shared.mainContext
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

        if WordPressAuthenticator.dotComWebLoginEnabled {
            let signedInAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
            Task { @MainActor in
                Notice(
                    title: NSLocalizedString("wpcom.token.fix.signin", value: "Sign in to WordPress.com", comment: "Message title to be displayed when the user needs to re-authenticate their WordPress.com account."),
                    message: NSLocalizedString("wpcom.token.fix.signin.message", value: "You need to sign in to WordPress.com to access your account.", comment: "Detailed message to be displayed when the user needs to re-authenticate their WordPress.com account.")
                ).post()

                let _ = await WordPressDotComAuthenticator().signIn(
                    from: presenter,
                    context: signedInAccount?.email
                        .flatMap { .reauthentication(accountEmail: $0) }
                        ?? .default
                )

                isPresentingSignIn = false
            }
        } else {
            let controller = signinForWPComFixingAuthToken({ (_) in
                isPresentingSignIn = false
            })
            presenter.present(controller, animated: true)
        }
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
        let context = ContextManager.shared.mainContext

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
        let mainContext = ContextManager.shared.mainContext

        // If adding a self-hosted site, skip the Epilogue
        if let wporg = credentials.wporg,
           let blog = Blog.lookup(username: wporg.username, xmlrpc: wporg.xmlrpc, in: mainContext) {
            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                navigationController.dismiss(animated: true)
            }
            return
        }

        presentDefaultAccountPrimarySite(from: navigationController)

        onDismiss()
    }

    func presentDefaultAccountPrimarySite(from navigationController: UINavigationController) {
        let mainContext = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext) else {
            wpAssert(false)
            return
        }

        let sites = account.blogs ?? []

        guard var selectedBlog = sites.first else {
            if windowManager.isShowingFullscreenSignIn {
                windowManager.dismissFullscreenSignIn()
            } else {
                navigationController.dismiss(animated: true)
            }
            return
        }

        if let primarySiteID = account.primaryBlogID,
           let site = sites.first(where: { $0.dotComID == primarySiteID }) {
            selectedBlog = site
        }

        // If the user just signed in, refresh the A/B assignments
        ABTest.start()

        recentSiteService.touch(blog: selectedBlog)
        presentEnableNotificationsPrompt(in: navigationController, blog: selectedBlog)
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

            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn()
            } else {
                navigationController.dismiss(animated: true)
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
        let service = AccountService(coreDataStack: ContextManager.shared)
        let context = ContextManager.shared.mainContext
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
        let context = ContextManager.shared.mainContext
        let numberOfBlogs = (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.blogs?.count ?? 0

        return numberOfBlogs
    }
}

// MARK: - Onboarding Questions Prompt
private extension WordPressAuthenticationManager {
    private func presentEnableNotificationsPrompt(in navigationController: UINavigationController, blog: Blog, onDismiss: (() -> Void)? = nil) {
        let windowManager = self.windowManager

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
              !UserPersistentStoreFactory.instance().onboardingNotificationsPromptDisplayed,
              !UITestConfigurator.isEnabled(.disablePrompts) else {
            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                self.windowManager.showAppUI(for: blog)
            }
            return
        }

        let onEnableNotificationsCompletion = { [weak navigationController] in
            guard let navigationController else { return }

            if windowManager.isShowingFullscreenSignIn {
                windowManager.dismissFullscreenSignIn(completion: nil)
            } else {
                navigationController.dismiss(animated: true, completion: nil)
            }

            onDismiss?()
        }

        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .notDetermined else {
                onEnableNotificationsCompletion()
                return
            }
            let controller = OnboardingEnableNotificationsViewController(completion: onEnableNotificationsCompletion)
            navigationController.pushViewController(controller, animated: true)
        }
    }
}

// MARK: - WordPressAuthenticatorManager
//
private extension WordPressAuthenticationManager {
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
            let notification = isJetpackLogin == true ? .wordpressLoginFinishedJetpackLogin : Foundation.Notification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification)
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
