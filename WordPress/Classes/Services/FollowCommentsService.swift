import Foundation
import WordPressKit

class FollowCommentsService {

    let post: ReaderPost

    fileprivate let postID: UInt
    fileprivate let siteID: UInt
    fileprivate let remote: ReaderPostServiceRemote

    init?(post: ReaderPost) {
        guard let postID = post.postID as? UInt, let siteID = post.siteID as? UInt else {
                return nil
        }

        self.post = post
        self.postID = postID
        self.siteID = siteID

        let api = FollowCommentsService.apiForRequest()
        self.remote = ReaderPostServiceRemote(wordPressComRestApi: api)
    }

    /// Fetches the subscription status of the specified post for the current user.
    ///
    /// - Parameters:
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block  called if there is any error. `error` can be any underlying network error.
    func fetchSubscriptionStatus(success: @escaping (Bool) -> Void,
                                 failure: @escaping (Error?) -> Void) {
        remote.fetchSubscriptionStatus(forPost: postID,
                                       fromSite: siteID,
                                       success: success,



                                       failure: failure)
    }

    /// Toggles the subscription status of the specified post.
    ///
    /// - Parameters:
    ///   - isSubscribed: The current subscription status for the reader post.
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block  called if there is any error. `error` can be any underlying network error.
    func toggleSubscribed(_ isSubscribed: Bool,
                          success: @escaping () -> Void,
                          failure: @escaping (Error?) -> Void) {
        if isSubscribed {
            remote.unsubscribe(fromPost: postID,
                               forSite: siteID,
                               success: success,
                               failure: failure)
        } else {
            remote.subscribe(toPost: postID,
                             forSite: siteID,
                             success: success,
                             failure: failure)
        }
    }

}

extension FollowCommentsService {

    private static func apiForRequest() -> WordPressComRestApi {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken
        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }
}
