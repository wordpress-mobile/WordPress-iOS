import Foundation

/// Provides options for clients of WordPressAuthenticator
/// to signal what they expect WPAuthenticator to do in response to
/// `shouldPresentUsernamePasswordController`
///
/// @see WordPressAuthenticatorDelegate.shouldPresentUsernamePasswordController
public enum WordPressAuthenticatorResult {

    /// An error
    ///
    case error(value: Error)

    /// Boolean flag to indicate if UI providing entry for username and passsword
    /// should be presented
    ///
    case presentPasswordController(value: Bool)

    /// Present the view controller requesting the email address
    /// associated to the user's wordpress.com account
    ///
    case presentEmailController

    /// A view controller to be inserted into the navigation stack
    ///
    case injectViewController(value: UIViewController)
}
