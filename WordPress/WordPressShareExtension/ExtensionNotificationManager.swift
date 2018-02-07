import Foundation
import UserNotifications

/// This handles the scheduling of user notifications in app extensions only.
///
class ExtensionNotificationManager {
    /// Convenience function to schedule a local success notification.
    ///
    /// - Parameters:
    ///   - postID: ID string representing a post
    ///   - blogID: ID string representing a blog/site
    ///   - mediaItemCount: Number of media items included with the post. Default is 0.
    ///
    static func scheduleSuccessNotification(postID: String, blogID: String, mediaItemCount: Int = 0, notificationDate: Date = Date()) {
        let userInfo = makeUserInfoDict(postID: postID, blogID: blogID)
        let title = ShareNoticeText.successTitle(mediaItemCount: mediaItemCount)
        let body = notificationDate.mediumString()
        scheduleLocalNotification(title: title, body: body, category: ShareNoticeConstants.categorySuccessIdentifier, userInfo: userInfo)
    }

    /// Convenience function to schedule a local failure notification.
    ///
    /// - Parameters:
    ///   - postID: ID string representing a post
    ///   - blogID: ID string representing a blog/site
    ///   - mediaItemCount: Number of media items included with the post. Default is 0.
    ///
    static func scheduleFailureNotification(postID: String, blogID: String, mediaItemCount: Int = 0, notificationDate: Date = Date()) {
        let userInfo = makeUserInfoDict(postID: postID, blogID: blogID)
        let title = ShareNoticeText.successTitle(mediaItemCount: mediaItemCount)
        let body = notificationDate.mediumString()
        scheduleLocalNotification(title: title, body: body, category: ShareNoticeConstants.categoryFailureIdentifier, userInfo: userInfo)
    }

    /// Schedules a local notification with the provided content, category identifier, and time delay.
    ///
    /// - Parameters:
    ///   - title: Title of notification alert
    ///   - body: Body of notification alert
    ///   - category: The identifier of the app-defined category object.
    ///   - userInfo: Dictionary that represents the user info payload for the notification.
    ///   - interval: The time (in seconds) that must elapse before the trigger fires. This value must be greater than zero (default is 3 seconds).
    ///
    static func scheduleLocalNotification(title: String, body: String, category: String, userInfo: [String: Any]?, delay: TimeInterval = 3.0) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.categoryIdentifier = category
        if let userInfo = userInfo {
            notificationContent.userInfo = userInfo
        }

        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: notificationTrigger)
        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { error in
            if let error = error {
                DDLogError("Unable to add notification request (\(error), \(error.localizedDescription))")
            }
        })
    }

    private static func makeUserInfoDict(postID: String, blogID: String) -> [String: Any] {
        var userInfo = [String: Any]()
        userInfo[ShareNoticeUserInfoKey.postID] = postID
        userInfo[ShareNoticeUserInfoKey.blogID] = blogID
        return userInfo
    }
}
