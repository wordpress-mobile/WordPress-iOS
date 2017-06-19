import Foundation
import CocoaLumberjack
import UserNotifications

/// In this class, we'll encapsulate all of the code related to UNNotificationCategory and
/// UNNotificationAction instantiation, along with the required handlers.
///
final public class InteractiveNotificationsManager: NSObject {
    // MARK: - Public Properties


    /// Returns the shared InteractiveNotificationsManager instance.
    ///
    static let sharedInstance = InteractiveNotificationsManager()


    /// Returns the SharedApplication instance. This is meant for Unit Testing purposes.
    ///
    var sharedApplication: UIApplication {
        return UIApplication.shared
    }

    /// Returns the Core Data main context.
    ///
    var context: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    /// Returns a CommentService instance.
    ///
    var commentService: CommentService {
        return CommentService(managedObjectContext: context)
    }

    /// Returns a NotificationSyncMediator instance.
    ///
    var notificationSyncMediator: NotificationSyncMediator? {
       return NotificationSyncMediator()
    }

    // MARK: - Public Methods


    /// Registers the device for User Notifications.
    ///
    /// This method should be called once during the app initialization process.
    ///
    public func registerForUserNotifications() {
        if sharedApplication.isRunningSimulator() || build(.a8cBranchTest) {
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories(supportedNotificationCategories())
    }

    /// Requests authorization to interact with the user when notifications arrive.
    ///
    /// The first time this method is called it will ask the user for permission to show notifications.
    /// Because of this, this should be called only when we know we will need to show notifications (for instance, after login).
    ///
    public func requestAuthorization() {
        if sharedApplication.isRunningSimulator() || build(.a8cBranchTest) {
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { _ in })
    }

    /// Handle an action taken from a remote notification
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the action
    ///     - userInfo: The notification's Payload
    ///
    /// - Returns: True on success
    ///
    @discardableResult
    public func handleAction(with identifier: String, userInfo: NSDictionary, responseText: String?) -> Bool {
        guard AccountHelper.isDotcomAvailable(),
            let noteID = userInfo.object(forKey: "note_id") as? NSNumber,
            let siteID = userInfo.object(forKey: "blog_id") as? NSNumber,
            let commentID = userInfo.object(forKey: "comment_id") as? NSNumber else {
            return false
        }

        if identifier == UNNotificationDefaultActionIdentifier {
            showDetailsWithNoteID(noteID)
            return true
        }

        guard let action = NoteActionDefinition(rawValue: identifier) else {
            return false
        }

        switch action {
        case .CommentApprove:
            approveCommentWithCommentID(commentID, noteID: noteID, siteID: siteID)
        case .CommentLike:
            likeCommentWithCommentID(commentID, noteID: noteID, siteID: siteID)
        case .CommentReply:
            if let responseText = responseText {
                replyToCommentWithCommentID(commentID, noteID: noteID, siteID: siteID, content: responseText)
            } else {
                DDLogError("Tried to reply to a comment notification with no text")
            }
        }

        return true
    }


    // MARK: - Private Helpers


    /// Likes a comment and marks the associated notification as read
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///
    fileprivate func likeCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber) {
        commentService.likeComment(withID: commentID, siteID: siteID, success: {
            self.notificationSyncMediator?.markAsReadAndSync(noteID.stringValue)
            DDLogInfo("Liked comment from push notification")
        }, failure: { error in
            DDLogInfo("Couldn't like comment from push notification")
        })
    }


    /// Approves a comment and marks the associated notification as read
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///
    fileprivate func approveCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber) {
        commentService.approveComment(withID: commentID, siteID: siteID, success: {
            self.notificationSyncMediator?.markAsReadAndSync(noteID.stringValue)
            DDLogInfo("Successfully moderated comment from push notification")
        }, failure: { error in
            DDLogInfo("Couldn't moderate comment from push notification")
        })
    }


    /// Opens the details for a given notificationId
    ///
    /// - Parameter noteID: The Notification's Identifier
    ///
    fileprivate func showDetailsWithNoteID(_ noteId: NSNumber) {
        WPTabBarController.sharedInstance().showNotificationsTabForNote(withID: noteId.stringValue)
    }


    /// Replies to a comment and marks the associated notification as read
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///     - content: The text for the comment reply
    ///
    fileprivate func replyToCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber, content: String) {
        commentService.replyToComment(withID: commentID, siteID: siteID, content: content, success: {
            self.notificationSyncMediator?.markAsReadAndSync(noteID.stringValue)
            DDLogInfo("Successfully replied comment from push notification")
        }, failure: { error in
            DDLogInfo("Couldn't reply to comment from push notification")
        })
    }




    // MARK: - Private: UNNotification Helpers


    /// Returns a collection of *UNNotificationCategory* instances, for each one of the
    /// supported NoteCategoryDefinition enum case's.
    ///
    /// - Returns: A set of *UNNotificationCategory* instances.
    ///
    private func supportedNotificationCategories() -> Set<UNNotificationCategory> {
        let categories: [UNNotificationCategory] = NoteCategoryDefinition.allDefinitions.map({ $0.notificationCategory() })
        return Set(categories)
    }



    /// Describes information about Custom Actions that WPiOS can perform, as a response to
    /// a Push Notification event.
    ///
    fileprivate enum NoteCategoryDefinition: String {
        case CommentApprove         = "approve-comment"
        case CommentLike            = "like-comment"
        case CommentReply           = "replyto-comment"
        case CommentReplyWithLike   = "replyto-like-comment"

        var actions: [NoteActionDefinition] {
            switch self {
            case .CommentApprove:
                return [.CommentApprove]
            case .CommentLike:
                return [.CommentLike]
            case .CommentReply:
                return [.CommentReply]
            case .CommentReplyWithLike:
                return [.CommentReply, .CommentLike]
            }
        }


        var identifier: String {
            return rawValue
        }

        func notificationCategory() -> UNNotificationCategory {
            return UNNotificationCategory(
                identifier: identifier,
                actions: actions.map({ $0.notificationAction() }),
                intentIdentifiers: [],
                options: [])
        }

        static var allDefinitions = [CommentApprove, CommentLike, CommentReply, CommentReplyWithLike]
    }



    /// Describes the custom actions that WPiOS can perform in response to a Push notification.
    ///
    fileprivate enum NoteActionDefinition: String {
        case CommentApprove = "COMMENT_MODERATE_APPROVE"
        case CommentLike    = "COMMENT_LIKE"
        case CommentReply   = "COMMENT_REPLY"

        var description: String {
            switch self {
            case .CommentApprove:
                return NSLocalizedString("Approve", comment: "Approve comment (verb)")
            case .CommentLike:
                return NSLocalizedString("Like", comment: "Like (verb)")
            case .CommentReply:
                return NSLocalizedString("Reply", comment: "Reply to a comment (verb)")
            }
        }

        var destructive: Bool {
            return false
        }

        var identifier: String {
            return rawValue
        }

        var requiresAuthentication: Bool {
            return false
        }

        var requiresForeground: Bool {
            return false
        }

        var notificationActionOptions: UNNotificationActionOptions {
            var options = UNNotificationActionOptions()
            if requiresAuthentication {
                options.insert(.authenticationRequired)
            }
            if destructive {
                options.insert(.destructive)
            }
            if requiresForeground {
                options.insert(.foreground)
            }
            return options
        }

        func notificationAction() -> UNNotificationAction {
            switch self {
            case .CommentReply:
                return UNTextInputNotificationAction(identifier: identifier,
                                                     title: description,
                                                     options: notificationActionOptions,
                                                     textInputButtonTitle: NSLocalizedString("Reply", comment: ""),
                                                     textInputPlaceholder: NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view"))
            default:
                return UNNotificationAction(identifier: identifier, title: description, options: notificationActionOptions)
            }
        }

        static var allDefinitions = [CommentApprove, CommentLike, CommentReply]
    }
}


extension InteractiveNotificationsManager: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        let textInputResponse = response as? UNTextInputNotificationResponse

        if handleAction(with: response.actionIdentifier, userInfo: userInfo, responseText: textInputResponse?.userText) {
            completionHandler()
            return
        }

        // TODO:
        // =====
        // Refactor both PushNotificationsManager + InteractiveNotificationsManager:
        //
        //  -   InteractiveNotificationsManager should no longer be a singleton. Perhaps we could convert it into a struct.
        //      Plus int should probably be renamed into something more meaningful (and match the new framework's naming)
        //  -   New `NotificationsManager` class:
        //      -   Would inherit `PushNotificationsManager.handleNotification`
        //      -   Would deal with UserNotifications.framework
        //      -   Would use InteractiveNotificationsManager!
        //  -   Nuke `PushNotificationsManager`
        //
        //
        PushNotificationsManager.sharedInstance.handleNotification(userInfo) { _ in
            completionHandler()
        }
    }
}
