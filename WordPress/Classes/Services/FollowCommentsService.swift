import Foundation
import WordPressKit

class FollowCommentsService: NSObject {

    let post: ReaderPost

    fileprivate let postID: Int
    fileprivate let siteID: Int
    fileprivate let remote: ReaderPostServiceRemote

    @objc init?(post: ReaderPost) {
        guard let postID = post.postID as? Int, let siteID = post.siteID as? Int else {
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
    ///   - failure: Failure block called if there is any error.
    @objc func fetchSubscriptionStatus(success: @escaping (Bool) -> Void,
                                       failure: @escaping (Error?) -> Void) {
        remote.fetchSubscriptionStatus(for: postID,
                                       from: siteID,
                                       success: success,
                                       failure: failure)
    }

    /// Toggles the subscription status of the specified post.
    ///
    /// - Parameters:
    ///   - isSubscribed: The current subscription status for the reader post.
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block called if there is any error.
    @objc func toggleSubscribed(_ isSubscribed: Bool,
                                success: @escaping () -> Void,
                                failure: @escaping (Error?) -> Void) {
        if isSubscribed {
            remote.unsubscribeFromPost(with: postID,
                                       for: siteID,
                                       success: success,
                                       failure: failure)
        } else {
            remote.subscribeToPost(with: postID,
                                   for: siteID,
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
