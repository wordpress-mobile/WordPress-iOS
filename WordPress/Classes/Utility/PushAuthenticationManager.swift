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

@objc public class PushAuthenticationManager
{
    /**
    *  @brief      Returns the PushAuthenticator Singleton Instance
    */
    static let sharedInstance = PushAuthenticationManager()
    
    
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
    *
    *  @param       userInfo    Is the Notification's payload.
    */
    public func handlePushAuthenticationNotification(userInfo: NSDictionary?) {
        // Expired: Display a message!
        if isNotificationExpired(userInfo) {
            showLoginExpiredAlert()
            return
        }
        
        // Valid: Ask for approval
        if let token   = userInfo?["push_auth_token"]           as? String,
               message = userInfo?.valueForKeyPath("aps.alert") as? String
        {
            showLoginVerificationAlert(message) {
                let mainContext = ContextManager.sharedInstance().mainContext
                let service     = PushAuthenticationService(managedObjectContext: mainContext)
                
                service.authorizeLogin(token)
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
        let acceptButtonTitle   = NSLocalizedString("Approve", comment: "Approve action. Verb")
        
        UIAlertView.showWithTitle(title,
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
    private func showLoginVerificationAlert(message: String, onApprove: (() -> ())) {
        let title               = NSLocalizedString("Verify Login", comment: "Push Authentication Alert Title")
        let cancelButtonTitle   = NSLocalizedString("Ignore", comment: "Ignore action. Verb")
        let acceptButtonTitle   = NSLocalizedString("Approve", comment: "Approve action. Verb")
        
        UIAlertView.showWithTitle(title,
            message:            message,
            cancelButtonTitle: cancelButtonTitle,
            otherButtonTitles: [acceptButtonTitle as AnyObject])
            {
                (theAlertView: UIAlertView!, buttonIndex: Int) -> Void in
                
                if theAlertView.cancelButtonIndex != buttonIndex {
                    onApprove()
                }
            }
    }
    
    
    // MARK: - Private Internal Constants
    private let pushAuthenticationNoteType      = "push_auth"
    private let minimumRemainingExpirationTime  = NSTimeInterval(5)
    
    // MARK: - Private Internal Properties
    private var isAlertViewOnScreen: Bool       = false
}
