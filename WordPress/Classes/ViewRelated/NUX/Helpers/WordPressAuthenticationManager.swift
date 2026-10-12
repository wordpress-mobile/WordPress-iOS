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

    private let windowManager: WindowManager
    private let recentSiteService: RecentSitesService

    /// Blocks the app while the default WordPress.com account has no token.
    let signInGate: SignInGateCoordinator

    private var cancellables = Set<AnyCancellable>()

    @MainActor
    init(
        windowManager: WindowManager,
        recentSiteService: RecentSitesService = RecentSitesService()
    ) {
        let signInGate = SignInGateCoordinator(host: windowManager)
        self.windowManager = windowManager
        self.recentSiteService = recentSiteService
        self.signInGate = signInGate
        super.init()
        windowManager.signInGate = signInGate
    }
}

// MARK: - Observer Registration
//
extension WordPressAuthenticationManager {
    /// Wires up the observers backing the re-authentication flows: the WordPress.com
    /// sign-in gate and the invalid-application-password notification.
    ///
    @MainActor
    func startObservingSignInNotifications(notificationCenter: NotificationCenter = .default) {
        signInGate.startObserving(notificationCenter: notificationCenter)

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
