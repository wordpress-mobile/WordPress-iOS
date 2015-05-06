import Foundation


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
    *  @details     Checks if a given Push Notification is of the Push Authentication type.
    *
    *  @param       userInfo    Is the Notification's payload. Can be nil.
    *  @returns     True if the notification is of Push Authentication type
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
    public func handlPushAuthenticationNotification(userInfo: NSDictionary?) {
        
        let token   = userInfo?["push_auth_token"] as? String
        let title   = userInfo?["title"] as? String
        let aps     = userInfo?["aps"] as? NSDictionary
        let message = aps?["alert"] as? String

        if isAlertViewOnScreen != false || token == nil || title == nil || message == nil {
            return
        }

        showAlertView(title!, message: message!) { (accepted) -> () in
            if !accepted {
                return
            }
            
            let mainContext = ContextManager.sharedInstance().mainContext
            let service     = PushAuthenticationService(managedObjectContext: mainContext)
            service.authorizeLogin(token!)
        }
    }
    

    /**
    *  @details     Displays an AlertView asking for WordPress.com Confirmation.
    *
    *  @param       title       The title of the AlertView.
    *  @param       message     The message to be displayed.
    *  @param       completion  A closure that receives a parameter, indicating whether the login attempt was
    *                           confirmed or not.
    */
    private func showAlertView(title: String, message: String, completion: ((accepted: Bool) -> ())) {
        let cancelButtonTitle   = NSLocalizedString("Ignore", comment: "Ignore action. Verb")
        let acceptButtonTitle   = NSLocalizedString("Approve", comment: "Approve action. Verb")

        isAlertViewOnScreen = true
        
        UIAlertView.showWithTitle(title,
            message: message,
            cancelButtonTitle: cancelButtonTitle,
            otherButtonTitles: [acceptButtonTitle as AnyObject])
            {
                (theAlertView: UIAlertView!, buttonIndex: Int) -> Void in
                
                self.isAlertViewOnScreen = false
                let accepted = theAlertView.cancelButtonIndex != buttonIndex
                completion(accepted: accepted)
            }
    }
    
    
    // MARK: - Private Internal Constants
    private let pushAuthenticationNoteType = "push_auth"
    
    // MARK: - Private Internal Properties
    private var isAlertViewOnScreen: Bool = false
}
