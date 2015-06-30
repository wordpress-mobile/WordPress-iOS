import Foundation
import UIKit


/**
*  @class           PushAuthenticationManager
*  @brief           The purpose of this class is to handle WordPress.com Push Authentication Notifications.
*  @details         When logging into a WordPress.com that has 2FA enabled, the user will be presented with
*                   the possibility of authorizing access by means of a mobile device that's already authenticated.
*                   By doing so, WordPress.com backend will send a Push Notification, which is meant to be handled
*                   by this specific class.
*/

@objc public class PushAuthenticationManager : NSObject
{
    //
    // MARK: - Public Methods
    //
    var alertViewProxy = UIAlertViewProxy()
    let pushAuthenticationService:PushAuthenticationService
    
    override convenience init() {
        self.init(pushAuthenticationService: PushAuthenticationService(managedObjectContext: ContextManager.sharedInstance().mainContext))
    }
    
    public init(pushAuthenticationService: PushAuthenticationService) {
        self.pushAuthenticationService = pushAuthenticationService
        super.init()
    }
    
    /**
    *  @brief       Checks if a given Push Notification is a Push Authentication.
    *  @details     A Push Notification should be handled by this helper whenever the 'Type' field 
    *               is of the 'push_auth' kind.
    *
    *  @param       userInfo    Is the Notification's payload. Can be nil.
    *  @returns     True if the notification should be handled by this class
    */
    public func isPushAuthenticationNotification(userInfo: NSDictionary?) -> Bool {
        if let unwrappedNoteType = userInfo?["type"] as? String {
            return unwrappedNoteType == pushAuthenticationNoteType
        }

        return false
    }

    /**
    *  @details     Will display a popup requesting for permission to verify a WordPress.com login
    *               attempt. The notification's type *is expected* to be of the Push Authentication kind
    *               If the alertView is confirmed, will proceed notifying WordPress.com's backend.
    *               On error, the backend call to verify the WordPress.com login attempt will be retried
    *               a maximum of (three) times, automatically.
    *
    *  @param       userInfo    Is the Notification's payload.
    */
    public func handlePushAuthenticationNotification(userInfo: NSDictionary?) {
        // Expired: Display a message!
        if isNotificationExpired(userInfo) {
            showLoginExpiredAlert()
            WPAnalytics.track(.PushAuthenticationExpired)
            return
        }
        
        // Verify: Ask for approval
        let token   = userInfo?["push_auth_token"]           as? String
        let message = userInfo?.valueForKeyPath("aps.alert") as? String
            
        if token == nil || message == nil {
            return
        }
        
        showLoginVerificationAlert(message!) { (approved) -> () in
            if approved {
                self.authorizeLogin(token!, retryCount: self.initialRetryCount)
                WPAnalytics.track(.PushAuthenticationApproved)
            } else {
                WPAnalytics.track(.PushAuthenticationIgnored)
            }
        }
    }
    
    
    
    //
    // MARK: - Private Helpers
    //
    
    /**
    *  @details     Authorizes a WordPress.com login attempt.
    *
    *  @param       token       The login request token received in the Push Notification itself.
    *  @param       retryCount  The number of retries that have taken place.
    */
    private func authorizeLogin(token: String, retryCount: Int) {
        if retryCount == maximumRetryCount {
            WPAnalytics.track(.PushAuthenticationFailed)
            return
        }

        self.pushAuthenticationService.authorizeLogin(token) { (success) -> () in
            if !success {
                self.authorizeLogin(token, retryCount: (retryCount + 1))
            }
        }
    }
    
    
    /**
    *  @details     Checks if a given Push Authentication Notification has already expired.
    *
    *  @param       userInfo    Is the Notification's payload.
    */
    private func isNotificationExpired(userInfo: NSDictionary?) -> Bool {
        let rawExpiration = userInfo?["expires"] as? Int
        if rawExpiration == nil {
            return false
        }
        
        let parsedExpiration = NSDate(timeIntervalSince1970: NSTimeInterval(rawExpiration!))
        return parsedExpiration.timeIntervalSinceNow < minimumRemainingExpirationTime
    }
    
    
    /**
    *  @details     Displays an AlertView indicating that a Login Request has expired.
    */
    private func showLoginExpiredAlert() {
        let title               = NSLocalizedString("Login Request Expired", comment: "Login Request Expired")
        let message             = NSLocalizedString("The login request has expired. Log in to WordPress.com to try again.",
                                                    comment: "WordPress.com Push Authentication Expired message")
        let acceptButtonTitle   = NSLocalizedString("Accept", comment: "Accept. Verb")
        
        self.alertViewProxy.showWithTitle(title,
            message:            message,
            cancelButtonTitle:  acceptButtonTitle,
            otherButtonTitles:  nil,
            tapBlock:           nil)
    }
    
    /**
    *  @details     Displays an AlertView asking for WordPress.com Authentication Approval.
    *
    *  @param       message     The message to be displayed.
    *  @param       completion  A closure that receives a parameter, indicating whether the login attempt was
    *                           confirmed or not.
    */
    private func showLoginVerificationAlert(message: String, completion: ((approved: Bool) -> ())) {
        let title               = NSLocalizedString("Verify Sign In", comment: "Push Authentication Alert Title")
        let cancelButtonTitle   = NSLocalizedString("Ignore", comment: "Ignore action. Verb")
        let acceptButtonTitle   = NSLocalizedString("Approve", comment: "Approve action. Verb")
        
        self.alertViewProxy.showWithTitle(title,
            message:            message,
            cancelButtonTitle: cancelButtonTitle,
            otherButtonTitles: [acceptButtonTitle as AnyObject])
            {
                (theAlertView: UIAlertView!, buttonIndex: Int) -> Void in
                let approved = theAlertView.cancelButtonIndex != buttonIndex
                completion(approved: approved)
            }
    }
    
    
    // MARK: - Private Internal Constants
    private let initialRetryCount               = 0
    private let maximumRetryCount               = 3
    private let minimumRemainingExpirationTime  = NSTimeInterval(5)
    private let pushAuthenticationNoteType      = "push_auth"
}
