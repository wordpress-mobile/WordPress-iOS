import Foundation


/// The purpose of this service is to encapsulate the Restful API that performs Mobile 2FA
/// Code Verification.
///
@objc open class PushAuthenticationService: LocalCoreDataService {

    @objc open var authenticationServiceRemote: PushAuthenticationServiceRemote?

    /// Designated Initializer
    ///
    /// - Parameter managedObjectContext: A Reference to the MOC that should be used to interact with
    ///                                   the Core Data Persistent Store.
    ///
    public required override init(managedObjectContext: NSManagedObjectContext) {
        super.init(managedObjectContext: managedObjectContext)
        self.authenticationServiceRemote = PushAuthenticationServiceRemote(wordPressComRestApi: apiForRequest())
    }

    /// Authorizes a WordPress.com Login Attempt (2FA Protected Accounts)
    ///
    /// - Parameters:
    ///     - token: The Token sent over by the backend, via Push Notifications.
    ///     - completion: The completion block to be executed when the remote call finishes.
    ///
    @objc open func authorizeLogin(_ token: String, completion: @escaping ((Bool) -> ())) {
        if self.authenticationServiceRemote == nil {
            return
        }

        self.authenticationServiceRemote!.authorizeLogin(token,
            success: {
                            completion(true)
                        },
            failure: {
                            completion(false)
                        })

    }

    /// Helper method to get the WordPress.com REST Api, if any
    ///
    /// - Returns: WordPressComRestApi instance.  It can be an anonymous API instance if there are no credentials.
    ///
    fileprivate func apiForRequest() -> WordPressComRestApi {

        var api: WordPressComRestApi? = nil

        let accountService = AccountService(managedObjectContext: managedObjectContext)
        if let unwrappedRestApi = accountService.defaultWordPressComAccount()?.wordPressComRestApi {
            if unwrappedRestApi.hasCredentials() {
                api = unwrappedRestApi
            }
        }

        if api == nil {
            api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
        }

        return api!
    }
}
