import WordPressAuthenticator

protocol AuthenticationHandler {
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void)

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void, windowManager: WindowManager) -> Bool

    // WPAuthenticator style overrides
    var statusBarStyle: UIStatusBarStyle { get }
    var prologueViewController: UIViewController? { get }
    var buttonViewTopShadowImage: UIImage? { get }
    var prologueButtonsBackgroundColor: UIColor? { get }
    var prologuePrimaryButtonStyle: NUXButtonStyle? { get }
    var prologueSecondaryButtonStyle: NUXButtonStyle? { get }
}
