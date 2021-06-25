import Foundation
import WordPressKit

class FollowCommentsService: NSObject {

    let post: ReaderPost
    let remote: ReaderPostServiceRemote
    let context: NSManagedObjectContext

    fileprivate let postID: Int
    fileprivate let siteID: Int

    @objc required init?(post: ReaderPost,
                         remote: ReaderPostServiceRemote = ReaderPostServiceRemote.withDefaultApi()) {
        guard let postID = post.postID as? Int,
              let siteID = post.siteID as? Int,
              let context = post.managedObjectContext
        else {
            return nil
        }

        self.post = post
        self.context = context
        self.postID = postID
        self.siteID = siteID
        self.remote = remote
    }

    @objc class func createService(with post: ReaderPost) -> FollowCommentsService? {
        self.init(post: post)
    }

    /// Returns a Bool indicating whether or not the comments on the post can be followed.
    ///
    @objc var canFollowConversation: Bool {
        return post.canSubscribeComments
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
                                success: @escaping (Bool) -> Void,
                                failure: @escaping (Error?) -> Void) {
        let objID = post.objectID
        let context = self.context
        let successBlock = { (taskSuccessful: Bool) -> Void in
            let newIsSubscribed = !isSubscribed
            let followAction: FollowCommentsService.FollowAction = newIsSubscribed ? .followed : .unfollowed

            var properties = [String: Any]()
            properties[WPAppAnalyticsKeyFollowAction] = followAction.rawValue
            properties[WPAppAnalyticsKeyBlogID] = self.siteID
            WPAnalytics.trackReader(.readerToggleFollowConversation, properties: properties)

            context.perform {
                if let post = try? context.existingObject(with: objID) as? ReaderPost {
                    post.isSubscribedComments = newIsSubscribed
                }
                ContextManager.sharedInstance().save(context) {
                    DispatchQueue.main.async {
                        success(taskSuccessful)
                    }
                }
            }
        }

        if isSubscribed {
            remote.unsubscribeFromPost(with: postID,
                                       for: siteID,
                                       success: successBlock,
                                       failure: failure)
        } else {
            remote.subscribeToPost(with: postID,
                                   for: siteID,
                                   success: successBlock,
                                   failure: failure)
        }
    }

    private enum FollowAction: String {
        case followed
        case unfollowed
    }
}
