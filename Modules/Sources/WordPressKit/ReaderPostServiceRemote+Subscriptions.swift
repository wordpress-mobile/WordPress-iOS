import Foundation

extension ReaderPostServiceRemote {

    public enum ResponseError: Error {
        case decodingFailed
    }

    private enum Constants {
        static let isSubscribed = "i_subscribe"
        static let success = "success"
        static let receivesNotifications = "receives_notifications"

        /// Request parameter key used for updating the notification settings of a post subscription.
        static let receiveNotificationsRequestKey = "receive_notifications"
    }

    /// Fetches the subscription status of the specified post for the current user.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post.
    ///   - siteID: The ID of the site.
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block called if there is any error.
    @objc open func fetchSubscriptionStatus(for postID: Int,
                                              from siteID: Int,
                                              success: @escaping (Bool) -> Void,
                                              failure: @escaping (Error?) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/subscribers/mine", withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: nil, success: { response, _ in
            do {
                guard let responseObject = response as? [String: AnyObject],
                    let isSubscribed = responseObject[Constants.isSubscribed] as? Bool else {
                        throw ReaderPostServiceRemote.ResponseError.decodingFailed
                }

                success(isSubscribed)
            } catch {
                failure(error)
            }
        }) { error, _ in
            WPKitLogError("Error fetching subscription status: \(error)")
            failure(error)
        }
    }

    /// Mark a post as subscribed by the user.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post.
    ///   - siteID: The ID of the site.
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block called if there is any error.
    @objc open func subscribeToPost(with postID: Int,
                                      for siteID: Int,
                                      success: @escaping (Bool) -> Void,
                                      failure: @escaping (Error?) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/subscribers/new", withVersion: ._1_1)

        wordPressComRESTAPI.post(path, parameters: nil, success: { response, _ in
            do {
                guard let responseObject = response as? [String: AnyObject],
                    let subscribed = responseObject[Constants.success] as? Bool else {
                        throw ReaderPostServiceRemote.ResponseError.decodingFailed
                }

                success(subscribed)
            } catch {
                failure(error)
            }
        }) { error, _ in
            WPKitLogError("Error subscribing to comments in the post: \(error)")
            failure(error)
        }
    }

    /// Mark a post as unsubscribed by the user.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post.
    ///   - siteID: The ID of the site.
    ///   - success: Success block called on a successful fetch.
    ///   - failure: Failure block called if there is any error.
    @objc open func unsubscribeFromPost(with postID: Int,
                                          for siteID: Int,
                                          success: @escaping (Bool) -> Void,
                                          failure: @escaping (Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/subscribers/mine/delete", withVersion: ._1_1)

        wordPressComRESTAPI.post(path, parameters: nil, success: { response, _ in
            do {
                guard let responseObject = response as? [String: AnyObject],
                    let unsubscribed = responseObject[Constants.success] as? Bool else {
                        throw ReaderPostServiceRemote.ResponseError.decodingFailed
                }

                success(unsubscribed)
            } catch {
                failure(error)
            }
        }) { error, _ in
            WPKitLogError("Error unsubscribing from comments in the post: \(error)")
            failure(error)
        }
    }

    /// Updates the notification settings for a post subscription.
    ///
    /// When the `receivesNotification` parameter is set to `true`, the subscriber will receive a notification whenever there is a new comment on the
    /// subscribed post. Note that the subscriber will still receive emails. On the contrary, when the `receivesNotification` parameter is set to `false`,
    /// subscriber will no longer receive notifications for new comments, but will still receive emails. To fully unsubscribe, refer to the
    /// `unsubscribeFromPost` method.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post.
    ///   - siteID: The ID of the site.
    ///   - receiveNotifications: When the value is true, subscriber will also receive a push notification for new comments on the subscribed post.
    ///   - success: Closure called when the request has succeeded.
    ///   - failure: Closure called when the request has failed.
    @objc open func updateNotificationSettingsForPost(with postID: Int,
                                                      siteID: Int,
                                                      receiveNotifications: Bool,
                                                      success: @escaping () -> Void,
                                                      failure: @escaping (Error?) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/subscribers/mine/update", withVersion: ._1_1)

        wordPressComRESTAPI.post(path,
                                 parameters: [Constants.receiveNotificationsRequestKey: receiveNotifications] as [String: AnyObject],
                                 success: { response, _ in
            guard let responseObject = response as? [String: AnyObject],
                  let remoteReceivesNotifications = responseObject[Constants.receivesNotifications] as? Bool,
                  remoteReceivesNotifications == receiveNotifications else {
                      failure(ResponseError.decodingFailed)
                      return
                  }

            success()

        }, failure: { error, _ in
            WPKitLogError("Error updating post subscription: \(error)")
            failure(error)
        })
    }
}
