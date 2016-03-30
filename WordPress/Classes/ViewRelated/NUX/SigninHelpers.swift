import UIKit
import NSURL_IDN
import WordPressComAnalytics

/// A collection of helper methods for NUX.
///
class SigninHelpers
{
    /// Check if the passed string resembles an email address.
    ///
    /// - Parameters:
    ///     - string: A string that is potentially an email address.
    ///
    class func resemblesEmailAddress(string: String) -> Bool {
        // Matches a string that:
        // - Is one or more non-whitespace characters excluding @.
        // - Followed by one @ sign.
        // - Followed by one or more non-whitespace characters excluding . and @.
        // - Followed by one .
        // - Followed by one ore more non-whitespace characters excluding @.
        let regex = try! NSRegularExpression(pattern: "^[^@\\s]+@[^@.\\s]+\\.[^@\\s]+$", options: .CaseInsensitive)
        let matches = regex.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
        return matches.count > 0
    }


    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameters:
    ///     - string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    class func baseSiteURL(string: String) -> String {
        guard let siteURL = NSURL(string: NSURL.IDNDecodedURL(string)) else {
            return ""
        }

        var path = siteURL.absoluteString.lowercaseString

        if path.isWordPressComPath() {
            if siteURL.scheme.characters.count == 0 {
                path = "https://\(path)"
            } else if path.rangeOfString("http://") != nil {
                path = path.stringByReplacingOccurrencesOfString("http://", withString: "https://")
            }
        } else if siteURL.scheme.characters.count == 0 {
            path = "http://\(path)"
        }

        let wpLogin = try! NSRegularExpression(pattern: "/wp-login.php$", options: .CaseInsensitive)
        let wpadmin = try! NSRegularExpression(pattern: "/wp-admin/?$", options: .CaseInsensitive)
        let trailingSlash = try! NSRegularExpression(pattern: "/?$", options: .CaseInsensitive)

        path = wpLogin.stringByReplacingMatchesInString(path, options: .ReportCompletion, range: NSRange(location: 0, length: path.characters.count), withTemplate: "")
        path = wpadmin.stringByReplacingMatchesInString(path, options: .ReportCompletion, range: NSRange(location: 0, length: path.characters.count), withTemplate: "")
        path = trailingSlash.stringByReplacingMatchesInString(path, options: .ReportCompletion, range: NSRange(location: 0, length: path.characters.count), withTemplate: "")

        return path
    }


    // MARK: - Validation Helpers


    ///
    ///
    class func validateFieldsPopulatedForSignin(loginFields: LoginFields) -> Bool {
        return !loginFields.username.isEmpty &&
            !loginFields.password.isEmpty &&
            ( loginFields.userIsDotCom || !loginFields.siteUrl.isEmpty )
    }


    ///
    ///
    class func validateSiteForSignin(loginFields: LoginFields) -> Bool {
        guard let _ = NSURL(string: NSURL.IDNEncodedURL(loginFields.siteUrl)) else {
            return false
        }
        return true
    }


    // MARK: - Other Helpers


    /// Opens Safari to display the forgot password page for a wpcom or self-hosted 
    /// based on the passed LoginFields instance.
    ///
    /// - Parameters:
    ///     - loginFields: A LoginFields instance.
    ///
    class func openForgotPasswordURL(loginFields: LoginFields) {
        let baseURL = loginFields.userIsDotCom ? "https://wordpress.com" : SigninHelpers.baseSiteURL(loginFields.siteUrl)
        let forgotPasswordURL = NSURL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.sharedApplication().openURL(forgotPasswordURL)
    }



    // MARK: - 1Password Helper


    /// Request credentails from 1Password (if supported)
    ///
    /// - Parameters:
    ///     - sender: A UIView. Typically the button the user tapped on.
    ///
    class func fetchOnePasswordCredentials(controller: UIViewController, sourceView: UIView, loginFields: LoginFields, success: ((loginFields: LoginFields) -> Void)) {

        let loginURL = loginFields.userIsDotCom ? "wordpress.com" : loginFields.siteUrl

        let onePasswordFacade = OnePasswordFacade()
        onePasswordFacade.findLoginForURLString(loginURL, viewController: controller, sender: sourceView, completion: { (username: String!, password: String!, oneTimePassword: String!, error: NSError!) in
            guard error == nil else {
                DDLogSwift.logError("OnePassword Error: \(error.localizedDescription)")
                WPAppAnalytics.track(.OnePasswordFailed)
                return
            }

            guard let username = username, password = password else {
                return
            }

            if username.isEmpty || password.isEmpty {
                return
            }

            loginFields.username = username
            loginFields.password = password

            if oneTimePassword != nil {
                loginFields.multifactorCode = oneTimePassword
            }

            WPAppAnalytics.track(.OnePasswordLogin)

            success(loginFields: loginFields)
        })
        
    }


    // MARK: - Safari Stored Credentials Helpers


    static let LoginSharedWebCredentialFQDN: CFString = "wordpress.com"
    typealias SharedWebCredentialsCallback = ((credentialsFound: Bool, username: String?, password: String?) -> Void)


    /// Update safari stored credentials.
    ///
    /// - Parameters:
    ///     - loginFields: An instance of LoginFields
    ///
    class func updateSafariCredentialsIfNeeded(loginFields: LoginFields) {
        // Paranioa. Don't try and update credentials for self-hosted.
        if !loginFields.userIsDotCom {
            return;
        }

        // If the user changed screen names, don't try and update/create a new shared web credential.
        // We'll let Safari handle creating newly saved usernames/passwords.
        if loginFields.safariStoredUsernameHash != UInt(loginFields.username.hash) {
            return
        }

        // If the user didn't change the password from previousl filled password no update is needed.
        if loginFields.safariStoredPasswordHash == UInt(loginFields.password.hash) {
            return
        }

        // Update the shared credential
        let username: CFString = loginFields.username
        let password: CFString = loginFields.password

        SecAddSharedWebCredential(LoginSharedWebCredentialFQDN, username, password, { (error: CFError?) in
            guard error == nil else {
                let err = error! as NSError
                DDLogSwift.logError("Error occurred updating shared web credential: \(err.localizedDescription)");
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                WPAppAnalytics.track(WPAnalyticsStat.SafariCredentialsLoginUpdated)
            })
        })
    }


    /// Request shared safari credentials if they exist.
    ///
    /// - Parameters:
    ///     - completion: A completion block.
    ///
    class func requestSharedWebCredentials(completion: SharedWebCredentialsCallback) {
        SecRequestSharedWebCredential(LoginSharedWebCredentialFQDN, nil, { (credentials: CFArray?, error: CFError?) in
            DDLogSwift.logInfo("Completed requesting shared web credentials")
            guard error == nil else {
                let err = error! as NSError
                if err.code == -25300 {
                    // An OSStatus of -25300 is expected when no saved credentails are found.
                    DDLogSwift.logInfo("No shared web credenitals found.")
                } else {
                    DDLogSwift.logError("Error requesting shared web credentials: \(err.localizedDescription)")
                }
                dispatch_async(dispatch_get_main_queue(), {
                    completion(credentialsFound: false, username: nil, password: nil)
                })
                return
            }

            guard let credentials = credentials where CFArrayGetCount(credentials) > 0 else {
                // Saved credentials exist but were not selected.
                dispatch_async(dispatch_get_main_queue(), {
                    completion(credentialsFound: true, username: nil, password: nil)
                })
                return
            }

            // What a chore!
            let unsafeCredentials = CFArrayGetValueAtIndex(credentials, 0)
            let credentialsDict = unsafeBitCast(unsafeCredentials, CFDictionaryRef.self)

            let unsafeUsername = CFDictionaryGetValue(credentialsDict, unsafeAddressOf(kSecAttrAccount))
            let usernameStr = unsafeBitCast(unsafeUsername, CFString.self) as String

            let unsafePassword = CFDictionaryGetValue(credentialsDict, unsafeAddressOf(kSecSharedPassword))
            let passwordStr = unsafeBitCast(unsafePassword, CFString.self) as String

            dispatch_async(dispatch_get_main_queue(), {
                completion(credentialsFound: true, username: usernameStr, password: passwordStr)
            })
        })
    }
}
