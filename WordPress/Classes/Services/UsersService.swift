import Foundation
import WordPressKit


/// UserService is responsible for interacting with UserServiceRemoteXMLRPC to fetch User and Profile related details
/// from self-hosted blogs. See the PeopleService for WordPress.com blogs via the REST API.
///
open class UsersService {

    /// XMLRPC API associated to the Endpoint.
    ///
    let api: WordPressOrgXMLRPCApi

    /// Endpoint's Username.
    ///
    let username: String

    /// Endpoint's Password.
    ///
    let password: String


    /// Designated Initializer.
    ///
    init?(username: String, password: String, xmlrpc: String) {
        guard let endpoint = URL(string: xmlrpc) else {
            return nil
        }

        self.api = WordPressOrgXMLRPCApi(endpoint: endpoint)
        self.username = username
        self.password = password
    }

    /// Fetch profile information for the user of the specified blog.
    ///
    func fetchProfile(onCompletion: @escaping ((UserProfile?) -> Void)) {
        let remote = UsersServiceRemoteXMLRPC(api: api, username: username, password: password)
        remote.fetchProfile({ remoteProfile in

            var profile = UserProfile()
            profile.bio = remoteProfile.bio
            profile.displayName = remoteProfile.displayName
            profile.email = remoteProfile.email
            profile.firstName = remoteProfile.firstName
            profile.lastName = remoteProfile.lastName
            profile.nicename = remoteProfile.nicename
            profile.nickname = remoteProfile.nickname
            profile.url = remoteProfile.url
            profile.userID = remoteProfile.userID
            profile.username = remoteProfile.username

            onCompletion(profile)

        }, failure: { error in
            DDLogError(error.debugDescription)
            onCompletion(nil)
        })
    }
}
