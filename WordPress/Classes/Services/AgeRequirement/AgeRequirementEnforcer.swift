import UIKit
import WordPressData

@MainActor
final class AgeRequirementEnforcer: AgeRequirementEnforcing {
    private let coreDataStack: CoreDataStackSwift
    private let windowManager: () -> WindowManager?

    init(
        coreDataStack: CoreDataStackSwift = ContextManager.shared,
        windowManager: @escaping () -> WindowManager? = { WordPressAppDelegate.shared?.windowManager }
    ) {
        self.coreDataStack = coreDataStack
        self.windowManager = windowManager
    }

    var userState: AgeRequirementUserState {
        let context = coreDataStack.mainContext
        return AgeRequirementUserState(
            wpComSignedIn: (try? WPAccount.lookupDefaultWordPressComAccount(in: context)) != nil,
            selfHostedSiteCount: BlogQuery().hostedByWPCom(false).count(in: context)
        )
    }

    func enforceRestriction(userState: AgeRequirementUserState) async -> UIViewController? {
        guard let windowManager = windowManager() else {
            clearAccountAndSites(userState: userState)
            return nil
        }

        // Start the sign-in transition before signing out. Logging out posts the account-changed notification, whose
        // handler shows the sign-in UI only when it is not already showing, so this order avoids a second root
        // transition. The new root is installed synchronously, so the data work runs during the transition animation.
        await withCheckedContinuation { continuation in
            windowManager.showSignInUI {
                continuation.resume()
            }
            clearAccountAndSites(userState: userState)
        }

        return windowManager.topmostPresentedViewController
    }

    private func clearAccountAndSites(userState: AgeRequirementUserState) {
        removeSelfHostedSites()
        if userState.wpComSignedIn {
            AccountHelper.logOutDefaultWordPressComAccount()
        } else {
            AccountHelper.deleteAccountData()
        }
    }

    /// Removes sites without an account. Sites attached to the WordPress.com account (including Jetpack-connected
    /// ones) are removed by signing out.
    func removeSelfHostedSites() {
        let blogService = BlogService(coreDataStack: coreDataStack)
        Blog.selfHosted(in: coreDataStack.mainContext).forEach(blogService.remove(_:))
    }
}
