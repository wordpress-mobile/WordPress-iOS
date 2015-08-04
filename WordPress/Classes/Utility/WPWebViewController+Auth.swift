import UIKit



/**
*  @extension       WPWebViewController
*  @brief           This Extension encapsulates all of the Authentication related features that are 100% 
*                   tied up to the WordPress data model, so that the main WPWebViewController class
*                   may be distributed (in the future) in a separate repository.
*/

extension WPWebViewController {

    /**
    *  @brief       This class helper method will return a WPWebViewController instance, already
    *               preinitialized with the Main Account's Username and Bearer Token (if any).
    */
    public class func authenticatedWebViewController(URL: NSURL!) -> WPWebViewController {
        assert(URL != nil)
        
        let webViewController = WPWebViewController(URL: URL)
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        if let defaultAccount = service.defaultWordPressComAccount() {
            webViewController.username  = defaultAccount.username
            webViewController.authToken = defaultAccount.authToken
        }
        
        return webViewController
    }
}
