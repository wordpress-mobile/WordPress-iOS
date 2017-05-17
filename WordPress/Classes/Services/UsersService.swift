import Foundation

public enum UsersServiceError: Int, Error {
    case BlogNotSelfhosted
}

/// UserService is responsible for interacting with UserServiceRemoteXMLRPC to 
/// fetch User and Profile related details from self-hosted blogs.  See the
/// PeopleService for WordPress.com blogs via the REST API.
///
open class UsersService {

    /// Fetch profile information for the user of the specified blog.
    ///
    func fetchProfile(blog: Blog, success: @escaping ((UserProfile) -> Void), failure: @escaping ((NSError?) -> Void)) {
        guard let api = blog.xmlrpcApi, let username = blog.username, let password = blog.password else {
            assertionFailure("Only self-hosted blogs are allowed.")
            failure(UsersServiceError.BlogNotSelfhosted as NSError)
            return
        }

        let remote = UsersServiceRemoteXMLRPC(api: api, username: username, password: password)
        remote.fetchProfile({ (remoteProfile) in

            let profile = UserProfile()
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

            success(profile)

        }, failure: { (error) in
            failure(error)
        })
    }
}
