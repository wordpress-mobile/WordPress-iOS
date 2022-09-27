import WordPressAuthenticator

protocol AuthenticationHandler {

    // WPAuthenticator style overrides
    var statusBarStyle: UIStatusBarStyle { get }
    var prologueViewController: UIViewController? { get }
    var buttonViewTopShadowImage: UIImage? { get }
    var prologueButtonsBackgroundColor: UIColor? { get }
    var prologueButtonsBlurEffect: UIBlurEffect? { get }
    var prologueBackgroundImage: UIImage? { get }
    var prologuePrimaryButtonStyle: NUXButtonStyle? { get }
    var prologueSecondaryButtonStyle: NUXButtonStyle? { get }
}
