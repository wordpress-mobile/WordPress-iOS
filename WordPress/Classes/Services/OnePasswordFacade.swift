import Foundation
import UIKit
import OnePasswordExtension



// MARK: - This protocol is a Facade that hides some of the implementation details for interacting with 1Password.
//
class OnePasswordFacade {

    /// This method will pull up the 1Password extension and display any logins for the passed in `loginUrl`.
    ///
    /// - Parameters:
    ///     - url: URL of the site in question.
    ///     - viewController: ViewController of the class that needs the 1Password extension to appear.
    ///     - sender: the control that triggered the action.
    ///     - success: closure that is called when 1Password successfully retrieves credentials.
    ///     - failure: closure that is called when 1Password couldn't find any credentials.
    ///
    func findLogin(for url: String,
                   viewController: UIViewController,
                   sender: Any,
                   success: @escaping (_ username: String, _ password: String, _ otp: String?) -> Void,
                   failure: @escaping (OnePasswordError) -> Void)
    {
        OnePasswordExtension.shared().findLogin(forURLString: url, for: viewController, sender: sender) { (dictionary, error) in
            if let error = error as NSError? {
                failure(OnePasswordError(error: error))
                return
            }

            guard let username = dictionary?[AppExtensionUsernameKey] as? String,
                let password = dictionary?[AppExtensionPasswordKey] as? String,
                !username.isEmpty,
                !password.isEmpty
            else {
                failure(.unknown)
                return
            }

            let oneTimePassword = dictionary?[AppExtensionTOTPKey] as? String
            success(username, password, oneTimePassword)
        }
    }

    /// Stores a new entry in the 1Password extension.
    ///
    /// - Parameters:
    ///     - url: the URL of the site in question.
    ///     - username: The username to store.
    ///     - password: The password to store.
    ///     - title: Title of the password to be stored.
    ///     - minimumLength: Generated Password's Minimum Length.
    ///     - maximumLength: Generated Password's Maximum Length.
    ///     - viewController: ViewController of the class that needs the 1Password extension to appear.
    ///     - sender: The control that triggered the action.
    ///     - success: Closure that is called when 1Password successfully store the credentials.
    ///     - failure: Closure that is called when 1Password failed to store credentials.
    ///
    func createLogin(url: String = OnePasswordDefaults.dotcomURL,
                     username: String,
                     password: String,
                     title: String = OnePasswordDefaults.passwordTitle,
                     minimumLength: Int = OnePasswordDefaults.minimumLength,
                     maximumLength: Int = OnePasswordDefaults.maximumLength,
                     for viewController: UIViewController,
                     sender: Any,
                     success: @escaping (_ username: String, _ password: String) -> Void,
                     failure: @escaping (OnePasswordError) -> Void)
    {
        let loginDetails = [
            AppExtensionTitleKey: title,
            AppExtensionUsernameKey: username,
            AppExtensionPasswordKey: password
        ]

        let options = [
            AppExtensionGeneratedPasswordMinLengthKey: minimumLength,
            AppExtensionGeneratedPasswordMaxLengthKey: maximumLength
        ]

        OnePasswordExtension.shared().storeLogin(forURLString: url, loginDetails: loginDetails, passwordGenerationOptions: options, for: viewController, sender: sender) { (loginDict, error) in
            if let error = error as NSError? {
                failure(OnePasswordError(error: error))
                return
            }

            guard let username = loginDict?[AppExtensionUsernameKey] as? String,
                let password = loginDict?[AppExtensionPasswordKey] as? String
            else {
                failure(.unknown)
                return
            }

            success(username, password)
        }
    }

    /// Indicates if the 1P Extension is enabled, or not.
    ///
    static var isOnePasswordEnabled: Bool {
        return OnePasswordExtension.shared().isAppExtensionAvailable()
    }
}


// MARK: - Default Settings
//
enum OnePasswordDefaults {

    /// WordPress.com default URL
    ///
    static let dotcomURL = "wordpress.com"

    /// Default minimum length of the generated password.
    ///
    static let minimumLength = 7

    /// Default maximum length of the generated password.
    ///
    static let maximumLength = 50

    /// Default Password Title.
    ///
    static let passwordTitle = "WordPress"
}


// MARK: - OnePasswordError
//
enum OnePasswordError: Error {
    case cancelledByUser
    case failedToRetrieveCredentials
    case unknown

    init(error: NSError) {
        switch error.code {
        case Int(AppExtensionErrorCodeCancelledByUser):
            self = .cancelledByUser
        default:
            self = .unknown
        }
    }
}
