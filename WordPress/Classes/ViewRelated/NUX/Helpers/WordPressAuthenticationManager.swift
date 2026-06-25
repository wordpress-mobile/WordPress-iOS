import Combine
import UIKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI
import WordPressCore

// MARK: - WordPressAuthenticationManager
//
/// Handles re-authentication notifications for WordPress.com and self-hosted sites, and presents the post-sign-in epilogue flow.
class WordPressAuthenticationManager: NSObject {
    // Keep this name stable so external observers registered against the string don't break.
    static let WPSigninDidFinishNotification = "WPSigninDidFinishNotification"

    static var isPresentingSignIn = false
    private let windowManager: WindowManager
    private let recentSiteService: RecentSitesService

    private var cancellables = Set<AnyCancellable>()

    init(
        windowManager: WindowManager,
        recentSiteService: RecentSitesService = RecentSitesService()
    ) {
        self.windowManager = windowManager
        self.recentSiteService = recentSiteService
    }
}

// MARK: - Observer Registration
//
extension WordPressAuthenticationManager {
    /// Wires up the observers backing the re-authentication flows: the WordPress.com
    /// auth-token-fixing notification and the invalid-application-password notification.
    ///
    func startObservingSignInNotifications(notificationCenter: NotificationCenter = .default) {
        notificationCenter
            .addObserver(
                self,
                selector: #selector(accontRequiresShowingWPComSigninReceived),
                name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
                object: nil
            )

        notificationCenter.publisher(for: WordPressClient.requestedWithInvalidAuthenticationNotification)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink {
                guard let blogId = $0.object as? TaggedManagedObjectID<Blog> else {
                    wpAssertionFailure(
                        "No blog ID found in the requestedWithInvalidAuthenticationNotification notification"
                    )
                    return
                }

                WordPressAuthenticationManager.showSigninForSelfHostedSiteFixingApplicationPassword(blogId: blogId)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Static Methods
//
extension WordPressAuthenticationManager {

    /// Presents the web-based WordPress.com sign-in flow from the rootViewController,
    /// so the user can re-authenticate and fix the invalid auth token of the default
    /// WordPress.com account.
    ///
    static func showSigninForWPComFixingAuthToken(showNotice: Bool = true) {
        guard let presenter = UIApplication.shared.mainWindow?.rootViewController else {
            assertionFailure()
            return
        }

        guard !isPresentingSignIn else {
            return
        }

        isPresentingSignIn = true

        let signedInAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        Task { @MainActor in
            let title = NSLocalizedString(
                "wpcom.token.fix.signin",
                value: "Sign in to WordPress.com",
                comment:
                    "Message title to be displayed when the user needs to re-authenticate their WordPress.com account."
            )
            let message = NSLocalizedString(
                "wpcom.token.fix.signin.message",
                value: "You need to sign in to WordPress.com to access your account.",
                comment:
                    "Detailed message to be displayed when the user needs to re-authenticate their WordPress.com account."
            )

            if showNotice {
                Notice(title: title, message: message).post()
            }

            let account = await WordPressDotComAuthenticator()
                .signIn(
                    from: presenter,
                    context: signedInAccount?.email
                        .flatMap { .reauthentication(accountEmail: $0) }
                        ?? .default
                )

            if account == nil {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addActionWithTitle(
                    NSLocalizedString(
                        "wpcom.token.alert.button.logout",
                        value: "Log out",
                        comment: "Button title to log out the current WordPress.com account"
                    ),
                    style: .destructive
                ) { _ in
                    AccountHelper.logOutDefaultWordPressComAccount()
                }
                alert.addActionWithTitle(
                    NSLocalizedString(
                        "wpcom.token.alert.button.signin",
                        value: "Sign In",
                        comment: "Button title to Sign In to WordPress.com"
                    ),
                    style: .default
                ) { _ in
                    WordPressAuthenticationManager.showSigninForWPComFixingAuthToken(showNotice: false)
                }
                presenter.present(alert, animated: true)
            }

            isPresentingSignIn = false
        }
    }

    static func showSigninForSelfHostedSiteFixingApplicationPassword(
        blogId: TaggedManagedObjectID<Blog>,
        showNotice: Bool = true
    ) {
        guard let presenter = UIViewController.topViewController,
            !presenter.isApplicationReauthentication
        else {
            assertionFailure()
            return
        }

        guard let currentBlog = RootViewCoordinator.sharedPresenter.currentlyVisibleBlog(),
            currentBlog.objectID == blogId.objectID
        else {
            DDLogWarn("Requested sign in to a site that is not the currently visible one")
            return
        }

        try? currentBlog.deleteApplicationToken()

        let rootView = ApplicationPasswordReAuthenticationView(blog: currentBlog, presenter: presenter)
        let viewController = UIHostingController(rootView: rootView)
        viewController.isModalInPresentation = true
        viewController.isApplicationReauthentication = true
        presenter.present(viewController, animated: true)
    }
}

// MARK: - Notification Handlers
//
extension WordPressAuthenticationManager {
    @objc func accontRequiresShowingWPComSigninReceived(_ notification: Foundation.Notification) {
        DispatchQueue.main.async {
            WordPressAuthenticationManager.showSigninForWPComFixingAuthToken()
        }
    }
}

// MARK: - Sign-In Epilogue
//
extension WordPressAuthenticationManager {

    func presentLoginEpilogue(
        in navigationController: UINavigationController,
        forSelfHostedSite blog: Blog?,
        onDismiss: @escaping () -> Void
    ) {
        // If adding a self-hosted site, skip the Epilogue
        if let blog {
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
            let site = sites.first(where: { $0.dotComID == primarySiteID })
        {
            selectedBlog = site
        }

        // If the user just signed in, refresh the A/B assignments
        ABTest.start()

        recentSiteService.touch(blog: selectedBlog)
        presentEnableNotificationsPrompt(in: navigationController, blog: selectedBlog)
    }
}

// MARK: - Onboarding Questions Prompt
private extension WordPressAuthenticationManager {
    private func presentEnableNotificationsPrompt(
        in navigationController: UINavigationController,
        blog: Blog,
        onDismiss: (() -> Void)? = nil
    ) {
        let windowManager = self.windowManager

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
            !UserPersistentStoreFactory.instance().onboardingNotificationsPromptDisplayed
        else {
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

private var isApplicationReauthenticationKey = 0

private extension UIViewController {

    var isApplicationReauthentication: Bool {
        set {
            objc_setAssociatedObject(
                self,
                &isApplicationReauthenticationKey,
                NSNumber(value: newValue),
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
            )
        }
        get {
            (objc_getAssociatedObject(self, &isApplicationReauthenticationKey) as? NSNumber)?.boolValue ?? false
        }
    }
}
