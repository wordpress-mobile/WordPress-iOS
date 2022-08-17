import WordPressAuthenticator

protocol AuthenticationHandler {

    /// Whether or not the AuthenticationHandler will override or handle the `presentLoginEpilogue` method.
    /// If this returns true, the `AuthenticationHandler.presentLoginEpilogue` method is called
    /// If not, then the default implementation will be called instead
    /// - Returns: Bool, true if we should override the functionality, false if we should not
    func willHandlePresentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials) -> Bool

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, windowManager: WindowManager, onDismiss: @escaping () -> Void) -> Bool

    /// Whether or not the AuthenticationHandler will override or handle the `presentSignupEpilogue` method.
    /// If this returns true, the `AuthenticationHandler.presentSignupEpilogue` method is called
    /// If not, then the default implementation will be called instead
    /// - Returns: Bool, true if we should override the functionality, false if we should not
    func willHandlePresentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) -> Bool

    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?)

    // WPAuthenticator style overrides
    var statusBarStyle: UIStatusBarStyle { get }
    var prologueViewController: UIViewController? { get }
    var buttonViewTopShadowImage: UIImage? { get }
    var prologueButtonsBackgroundColor: UIColor? { get }
    var prologuePrimaryButtonStyle: NUXButtonStyle? { get }
    var prologueSecondaryButtonStyle: NUXButtonStyle? { get }
}
