import Foundation
import WordPressKit

class FollowCommentsService: NSObject {

    let post: ReaderPost
    let remote: ReaderPostServiceRemote
    private let coreDataStack: CoreDataStack

    fileprivate let postID: Int
    fileprivate let siteID: Int

    required init?(
        post: ReaderPost,
        coreDataStack: CoreDataStack = ContextManager.shared,
        remote: ReaderPostServiceRemote = ReaderPostServiceRemote.withDefaultApi()
    ) {
        guard let postID = post.postID as? Int,
              let siteID = post.siteID as? Int
        else {
            return nil
        }

        self.post = post
        self.coreDataStack = coreDataStack
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
        let successBlock = { (taskSuccessful: Bool) -> Void in
            self.coreDataStack.performAndSave({ context in
                if let post = try? context.existingObject(with: objID) as? ReaderPost {
                    post.isSubscribedComments = !isSubscribed
                }
            }, completion: {
                success(taskSuccessful)
            }, on: .main)
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

    /// Toggles the notification setting for a specified post.
    ///
    /// - Parameters:
    ///   - isNotificationsEnabled: Determines whether the user should receive notifications for new comments on the specified post.
    ///   - success: Block called after the operation completes successfully.
    ///   - failure: Block called when the operation fails.
    @objc func toggleNotificationSettings(_ isNotificationsEnabled: Bool,
                                          success: @escaping () -> Void,
                                          failure: @escaping (Error?) -> Void) {

        remote.updateNotificationSettingsForPost(with: postID, siteID: siteID, receiveNotifications: isNotificationsEnabled) { [weak self] in
            guard let self = self else {
                failure(nil)
                return
            }

            self.coreDataStack.performAndSave({ context in
                if let post = try? context.existingObject(with: self.post.objectID) as? ReaderPost {
                    post.receivesCommentNotifications = isNotificationsEnabled
                }
            }, completion: success, on: .main)
        } failure: { error in
            DDLogError("Error updating notification settings for followed conversation: \(String(describing: error))")
            failure(error)
        }
    }

}
