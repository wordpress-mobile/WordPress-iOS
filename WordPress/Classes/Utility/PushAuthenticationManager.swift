import Foundation
import UIKit
import WordPressComAnalytics


/// The purpose of this class is to handle WordPress.com Push Authentication Notifications.
/// When logging into a WordPress.com that has 2FA enabled, the user will be presented with the possibility of
/// authorizing access by means of a mobile device that's already authenticated.
/// By doing so, WordPress.com backend will send a Push Notification, which is meant to be handled by this specific class.
///
@objc open class PushAuthenticationManager: NSObject {
    // MARK: - Public Methods
    //
    open var alertControllerProxy = UIAlertControllerProxy()
    open let pushAuthenticationService: PushAuthenticationService

    override convenience init() {
        let context = ContextManager.sharedInstance().mainContext
        let service = PushAuthenticationService(managedObjectContext: context)
        self.init(pushAuthenticationService: service)
    }

    public init(pushAuthenticationService: PushAuthenticationService) {
        self.pushAuthenticationService = pushAuthenticationService
        super.init()
    }


    /// Checks if a given Push Notification is a Push Authentication.
    ///
    /// - Note: A Push Notification should be handled by this helper whenever the 'Type' field is of the 'push_auth' kind.
    ///
    /// - Parameter userInfo: Is the Notification's payload. Can be nil.
    ///
    /// - Returns: True if the notification should be handled by this class
    ///
    open func isPushAuthenticationNotification(_ userInfo: NSDictionary?) -> Bool {
        if let unwrappedNoteType = userInfo?["type"] as? String {
            return unwrappedNoteType == pushAuthenticationNoteType
        }

        return false
    }

    /// Will display a popup requesting for permission to verify a WordPress.com login attempt.
    /// The notification's type *is expected* to be of the Push Authentication kind.
    /// If the alertView is confirmed, will proceed notifying WordPress.com's backend.
    /// On error, the backend call to verify the WordPress.com login attempt will be retried a maximum of (three) times,
    /// automatically.
    ///
    /// - Parameter userInfo: Is the Notification's payload.
    ///
    open func handlePushAuthenticationNotification(_ userInfo: NSDictionary?) {
        // Expired: Display a message!
        if isNotificationExpired(userInfo) {
            showLoginExpiredAlert()
            WPAnalytics.track(.pushAuthenticationExpired)
            return
        }

        // Verify: Ask for approval
        guard let token = userInfo?["push_auth_token"] as? String,
            let message = userInfo?.value(forKeyPath: "aps.alert") as? String else {
            return
        }

        showLoginVerificationAlert(message) { approved in
            if approved {
                self.authorizeLogin(token, retryCount: self.initialRetryCount)
                WPAnalytics.track(.pushAuthenticationApproved)
            } else {
                WPAnalytics.track(.pushAuthenticationIgnored)
            }
        }
    }



    // MARK: - Private Helpers
    //

    /// Authorizes a WordPress.com login attempt.
    ///
    /// - Parameters:
    ///     - token: The login request token received in the Push Notification itself.
    ///     - retryCount: The number of retries that have taken place.
    ///
    fileprivate func authorizeLogin(_ token: String, retryCount: Int) {
        if retryCount == maximumRetryCount {
            WPAnalytics.track(.pushAuthenticationFailed)
            return
        }

        self.pushAuthenticationService.authorizeLogin(token) { success in
            if !success {
                self.authorizeLogin(token, retryCount: (retryCount + 1))
            }
        }
    }


    /// Checks if a given Push Authentication Notification has already expired.
    ///
    /// - Parameter userInfo: Is the Notification's payload.
    ///
    fileprivate func isNotificationExpired(_ userInfo: NSDictionary?) -> Bool {
        let rawExpiration = userInfo?["expires"] as? TimeInterval
        if rawExpiration == nil {
            return false
        }

        let parsedExpiration = Date(timeIntervalSince1970: TimeInterval(rawExpiration!))
        return parsedExpiration.timeIntervalSinceNow < minimumRemainingExpirationTime
    }


    /// Displays an AlertView indicating that a Login Request has expired.
    ///
    fileprivate func showLoginExpiredAlert() {
        let title               = NSLocalizedString("Login Request Expired", comment: "Login Request Expired")
        let message             = NSLocalizedString("The login request has expired. Log in to WordPress.com to try again.",
                                                    comment: "WordPress.com Push Authentication Expired message")
        let acceptButtonTitle   = NSLocalizedString("OK", comment: "OK")

        alertControllerProxy.show(withTitle: title,
            message:            message,
            cancelButtonTitle:  acceptButtonTitle,
            otherButtonTitles:  nil,
            tap:           nil)
    }

    /// Displays an AlertView asking for WordPress.com Authentication Approval.
    ///
    /// - Parameters:
    ///     - message: The message to be displayed.
    ///     - completion: A closure that receives a parameter, indicating whether the login attempt was confirmed or not.
    ///
    fileprivate func showLoginVerificationAlert(_ message: String, completion: @escaping ((_ approved: Bool) -> ())) {
        let title               = NSLocalizedString("Verify Log In", comment: "Push Authentication Alert Title")
        let cancelButtonTitle   = NSLocalizedString("Ignore", comment: "Ignore action. Verb")
        let acceptButtonTitle   = NSLocalizedString("Approve", comment: "Approve action. Verb")

        alertControllerProxy.show(withTitle: title,
                                           message: message,
                                           cancelButtonTitle: cancelButtonTitle,
                                           otherButtonTitles: [acceptButtonTitle]) { (theAlertController, buttonIndex) in
            let approved = theAlertController?.actions[buttonIndex].style != .cancel
            completion(approved)
        }
    }


    // MARK: - Private Internal Constants
    fileprivate let initialRetryCount                   = 0
    fileprivate let maximumRetryCount                   = 3
    fileprivate let minimumRemainingExpirationTime      = TimeInterval(5)
    fileprivate let pushAuthenticationNoteType          = "push_auth"
}
