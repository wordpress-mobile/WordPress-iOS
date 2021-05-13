import WordPressAuthenticator

protocol AuthenticationHandler {
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void)

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, windowManager: WindowManager, onDismiss: @escaping () -> Void) -> Bool

    // WPAuthenticator style overrides
    var statusBarStyle: UIStatusBarStyle { get }
    var prologueViewController: UIViewController? { get }
    var buttonViewTopShadowImage: UIImage? { get }
    var prologueButtonsBackgroundColor: UIColor? { get }
    var prologuePrimaryButtonStyle: NUXButtonStyle? { get }
    var prologueSecondaryButtonStyle: NUXButtonStyle? { get }
}
