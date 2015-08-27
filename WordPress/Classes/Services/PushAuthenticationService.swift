import Foundation


/**
*  @class           PushAuthenticationService
*  @brief           The purpose of this service is to encapsulate the Restful API that performs Mobile 2FA
*                   Code Verification.
*/

@objc public class PushAuthenticationService : LocalCoreDataService
{
    public var authenticationServiceRemote: PushAuthenticationServiceRemote?
    
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with
    *                                       the Core Data Persistent Store.
    */
    public required override init(managedObjectContext: NSManagedObjectContext) {
        super.init(managedObjectContext: managedObjectContext)
        self.authenticationServiceRemote = PushAuthenticationServiceRemote(api: apiForRequest())
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
    *  @returns     WordPressComApi instance.  It can be an anonymous API instance if there are no
    *               credentials.
    */
    private func apiForRequest() -> WordPressComApi {
        
        var api : WordPressComApi? = nil
        
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        if let unwrappedRestApi = accountService.defaultWordPressComAccount()?.restApi {
            if unwrappedRestApi.hasCredentials() {
                api = unwrappedRestApi
            }
        }
        
        if api == nil {
            api = WordPressComApi.anonymousApi()
        }
        
        return api!
    }
}
