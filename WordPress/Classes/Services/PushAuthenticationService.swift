import Foundation


/**
*  @class           PushAuthenticationService
*  @brief           The purpose of this service is to encapsulate the Restful API that performs Mobile 2FA
*                   Code Verification.
*/

@objc public class PushAuthenticationService : NSObject, LocalCoreDataService
{
    var authenticationServiceRemote:PushAuthenticationServiceRemote?
    
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with
    *                                       the Core Data Persistent Store.
    */
    public required init(managedObjectContext: NSManagedObjectContext) {
        super.init()
        self.managedObjectContext = managedObjectContext
        self.authenticationServiceRemote = PushAuthenticationServiceRemote(remoteApi: apiForRequest())
    }

    /**
    *  @details     Authorizes a WordPress.com Login Attempt (2FA Protected Accounts)
    *  @param       token       The Token sent over by the backend, via Push Notifications.
    *  @param       completion  The completion block to be executed when the remote call finishes.
    */
    public func authorizeLogin(token: String, completion: ((Bool) -> ())) {
        if self.authenticationServiceRemote == nil {
            return
        }
        
        self.authenticationServiceRemote!.authorizeLogin(token,
            success:    {
                            completion(true)
                        },
            failure:    {
                            completion(false)
                        })

    }
    
    /**
    *  @details     Helper method to get the WordPress.com REST Api, if any
    *  @returns     WordPressComApi instance, if applicable, or nil.
    */
    private func apiForRequest() -> WordPressComApi? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        if let unwrappedRestApi = accountService.defaultWordPressComAccount()?.restApi {
            if unwrappedRestApi.hasCredentials() {
                return unwrappedRestApi
            }
        }
        
        return nil
    }

    
    // MARK: - Private Internal Properties
    private var managedObjectContext : NSManagedObjectContext!
}
