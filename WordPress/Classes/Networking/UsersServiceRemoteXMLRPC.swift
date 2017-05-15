import Foundation

import AFNetworking

/// UsersServiceRemoteXMLRPC handles Users related XML-RPC calls.
/// https://codex.wordpress.org/XML-RPC_WordPress_API/Users
///
open class UsersServiceRemoteXMLRPC: ServiceRemoteWordPressXMLRPC {

    /// Fetch the blog user's profile.
    ///
    func fetchProfile(_ success: @escaping ((RemoteProfile) -> Void), failure: @escaping ((NSError?) -> Void)) {
        let params = defaultXMLRPCArguments() as [AnyObject]
        api.callMethod("wp.getProfile", parameters: params, success: { (responseObj, response) in
            guard let dict = responseObj as? NSDictionary else {
                assertionFailure("A dictionary was expected but the API returned something different.")
                return
            }
            let profile = RemoteProfile(dictionary: dict)
            success(profile)

        }, failure: { (error, response) in
            failure(error)
        })
    }

}
