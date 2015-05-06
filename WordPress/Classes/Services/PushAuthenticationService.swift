import Foundation


/**
*  @class           PushAuthenticationService
*  @brief           The purpose of this service is to encapsulate the Restful API that performs Mobile 2FA
*                   Code Verification.
*/

@objc public class PushAuthenticationService : NSObject, LocalCoreDataService
{
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with
    *                                       the Core Data Persistent Store.
    */
    public required init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    

    /**
    *  @details     Authorizes a WordPress.com Login Attempt (2FA Protected Accounts)
    *  @param       token   The Token sent over by the backend, via Push Notifications.
    */
    public func authorizeLogin(token: String) {
        authorizeLogin(token, retryCount: zeroRetryCount)
    }

    
    /**
    *  @details     Authorizes a WordPress.com Login Attempt (2FA Protected Accounts).
    *               The maximum allowed retries is specified by the 'maxRetryCount' constant.
    *  @param       token       The Token sent over by the backend, via Push Notifications.
    *  @param       retryCount  The number of retries that have taken place.
    */
    private func authorizeLogin(token: String, retryCount: Int) {
        if retryCount == maxRetryCount {
            return
        }
        
        let remoteService = PushAuthenticationServiceRemote(remoteApi: apiForRequest())
        if remoteService == nil {
            return
        }
        
        remoteService!.authorizeLogin(token,
            success:    nil,
            failure:    {
                            self.authorizeLogin(token, retryCount: (retryCount + 1))
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
    
    
    // MARK: - Private Constants
    private let zeroRetryCount  = 0
    private let maxRetryCount   = 3
    
    // MARK: - Private Internal Properties
    private var managedObjectContext : NSManagedObjectContext!
}
