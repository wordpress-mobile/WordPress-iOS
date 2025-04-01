@testable import WordPressAuthenticator
import WordPressKit
import WordPressShared

class WordPressAuthenticatorDelegateSpy: WordPressAuthenticatorDelegate {
    var dismissActionEnabled: Bool = true
    var supportActionEnabled: Bool = true
    var wpcomTermsOfServiceEnabled: Bool = true
    var showSupportNotificationIndicator: Bool = true
    var supportEnabled: Bool = true
    var allowWPComLogin: Bool = true
    var shouldHandleError: Bool = false

    private(set) var presentSignupEpilogueCalled = false
    private(set) var socialUser: SocialUser?

    func createdWordPressComAccount(username: String, authToken: String) {
        // no-op
    }

    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
        // no-op
    }

    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        // no-op
    }

    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {
        // no-op
    }

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, source: SignInSource?, onDismiss: @escaping () -> Void) {
        // no-op
    }

    func presentSignupEpilogue(
        in navigationController: UINavigationController,
        for credentials: AuthenticatorCredentials,
        socialUser: SocialUser?
    ) {
        presentSignupEpilogueCalled = true
        self.socialUser = socialUser
    }

    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, lastStep: AuthenticatorAnalyticsTracker.Step, lastFlow: AuthenticatorAnalyticsTracker.Flow) {
        // no-op
    }

    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        true
    }

    func shouldHandleError(_ error: Error) -> Bool {
        shouldHandleError
    }

    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {
        if shouldHandleError {
            onCompletion(UIViewController())
        }
    }

    func shouldPresentSignupEpilogue() -> Bool {
        true
    }

    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        // no-op
    }

    func track(event: WPAnalyticsStat) {
        // no-op
    }

    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        // no-op
    }

    func track(event: WPAnalyticsStat, error: Error) {
        // no-op
    }
}
