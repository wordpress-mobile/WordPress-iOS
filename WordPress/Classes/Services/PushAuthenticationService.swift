import Foundation

/// The purpose of this service is to encapsulate the Restful API that performs Mobile 2FA
/// Code Verification.
///
class PushAuthenticationService {

    var authenticationServiceRemote: PushAuthenticationServiceRemote?

    /// Designated Initializer
    ///
    /// - Parameter managedObjectContext: A Reference to the MOC that should be used to interact with
    ///                                   the Core Data Persistent Store.
    ///
    init(coreDataStack: CoreDataStack) {
        let api = coreDataStack.performQuery(self.apiForRequest(in:))
        self.authenticationServiceRemote = PushAuthenticationServiceRemote(wordPressComRestApi: api)
    }

    /// Authorizes a WordPress.com Login Attempt (2FA Protected Accounts)
    ///
    /// - Parameters:
    ///     - token: The Token sent over by the backend, via Push Notifications.
    ///     - completion: The completion block to be executed when the remote call finishes.
    ///
    func authorizeLogin(_ token: String, completion: @escaping ((Bool) -> ())) {
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
    private func apiForRequest(in context: NSManagedObjectContext) -> WordPressComRestApi {

        var api: WordPressComRestApi? = nil

        if let unwrappedRestApi = (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.wordPressComRestApi {
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
