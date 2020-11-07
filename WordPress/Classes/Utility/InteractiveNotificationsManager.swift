import Foundation
import CocoaLumberjack
import UserNotifications
import WordPressFlux

// MARK: - InteractiveNotificationsManager

/// In this class, we'll encapsulate all of the code related to UNNotificationCategory and
/// UNNotificationAction instantiation, along with the required handlers.
///
final class InteractiveNotificationsManager: NSObject {

    /// Returns the shared InteractiveNotificationsManager instance.
    ///
    @objc static let shared = InteractiveNotificationsManager()

    /// Returns the Core Data main context.
    ///
    @objc var context: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    /// Returns a CommentService instance.
    ///
    @objc var commentService: CommentService {
        return CommentService(managedObjectContext: context)
    }

    /// Returns a NotificationSyncMediator instance.
    ///
    var notificationSyncMediator: NotificationSyncMediator? {
       return NotificationSyncMediator()
    }


    /// Registers the device for User Notifications.
    ///
    /// This method should be called once during the app initialization process.
    ///
    @objc func registerForUserNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories(supportedNotificationCategories())
    }

    /// Requests authorization to interact with the user when notifications arrive.
    ///
    /// The first time this method is called it will ask the user for permission to show notifications.
    /// Because of this, this should be called only when we know we will need to show notifications (for instance, after login).
    ///
    @objc func requestAuthorization(completion: @escaping () -> ()) {
        defer {
            WPAnalytics.track(.pushNotificationOSAlertShown)
        }

        var options: UNAuthorizationOptions = [.badge, .sound, .alert]
        if #available(iOS 12.0, *) {
            options.insert(.providesAppNotificationSettings)
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: options) { (allowed, _)  in
            DispatchQueue.main.async {
                if allowed {
                    WPAnalytics.track(.pushNotificationOSAlertAllowed)
                } else {
                    WPAnalytics.track(.pushNotificationOSAlertDenied)
                }
            }
            completion()
        }
    }

    /// Handle an action taken from a remote notification
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the action
    ///     - userInfo: The notification's Payload
    ///
    /// - Returns: True on success
    ///
    @objc @discardableResult
    func handleAction(with identifier: String, category: String, userInfo: NSDictionary, responseText: String?) -> Bool {
        if let noteCategory = NoteCategoryDefinition(rawValue: category),
            noteCategory.isLocalNotification {
            return handleLocalNotificationAction(with: identifier, category: category, userInfo: userInfo, responseText: responseText)
        }

        if NoteActionDefinition.approveLogin == NoteActionDefinition(rawValue: identifier) {
            return approveAuthChallenge(userInfo)
        }

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

        var legacyAnalyticsEvent: WPAnalyticsStat? = nil
        switch action {
        case .commentApprove:
            legacyAnalyticsEvent = .notificationsCommentApproved
            approveCommentWithCommentID(commentID, noteID: noteID, siteID: siteID)
        case .commentLike:
            legacyAnalyticsEvent = .notificationsCommentLiked
            likeCommentWithCommentID(commentID, noteID: noteID, siteID: siteID)
        case .commentReply:
            if let responseText = responseText {
                legacyAnalyticsEvent = .notificationsCommentRepliedTo
                replyToCommentWithCommentID(commentID, noteID: noteID, siteID: siteID, content: responseText)
            } else {
                DDLogError("Tried to reply to a comment notification with no text")
            }
        default:
            break
        }

        if let actionEvent = legacyAnalyticsEvent {
            let modernEventProperties: [String: Any] = [
                WPAppAnalyticsKeyQuickAction: action.quickActionName,
                WPAppAnalyticsKeyBlogID: siteID,
                WPAppAnalyticsKeyCommentID: commentID
            ]
            WPAppAnalytics.track(.pushNotificationQuickActionCompleted, withProperties: modernEventProperties)

            let legacyEventProperties = [ WPAppAnalyticsKeyLegacyQuickAction: true ]
            WPAppAnalytics.track(actionEvent, withProperties: legacyEventProperties)
        }

        return true
    }

    func handleLocalNotificationAction(with identifier: String, category: String, userInfo: NSDictionary, responseText: String?) -> Bool {
        if let noteCategory = NoteCategoryDefinition(rawValue: category) {
            switch noteCategory {
            case .mediaUploadSuccess, .mediaUploadFailure:
                if identifier == UNNotificationDefaultActionIdentifier {
                    MediaNoticeNavigationCoordinator.navigateToMediaLibrary(with: userInfo)
                    return true
                }

                if let action = NoteActionDefinition(rawValue: identifier) {
                    switch action {
                    case .mediaWritePost:
                        MediaNoticeNavigationCoordinator.presentEditor(with: userInfo)
                    case .mediaRetry:
                        MediaNoticeNavigationCoordinator.retryMediaUploads(with: userInfo)
                    default:
                        break
                    }
                }
            case .postUploadSuccess, .postUploadFailure:
                if identifier == UNNotificationDefaultActionIdentifier {
                    ShareNoticeNavigationCoordinator.navigateToPostList(with: userInfo)
                    return true
                }

                if let action = NoteActionDefinition(rawValue: identifier) {
                    switch action {
                    case .postRetry:
                        PostNoticeNavigationCoordinator.retryPostUpload(with: userInfo)
                    case .postView:
                        PostNoticeNavigationCoordinator.presentPostEpilogue(with: userInfo)
                    default:
                        break
                    }
                }
            case .shareUploadSuccess:
                if identifier == UNNotificationDefaultActionIdentifier {
                    ShareNoticeNavigationCoordinator.navigateToPostList(with: userInfo)
                    return true
                }

                if let action = NoteActionDefinition(rawValue: identifier) {
                    switch action {
                    case .shareEditPost:
                        ShareNoticeNavigationCoordinator.presentEditor(with: userInfo)
                    default:
                        break
                    }
                }
            case .shareUploadFailure:
                if identifier == UNNotificationDefaultActionIdentifier {
                    ShareNoticeNavigationCoordinator.navigateToBlogDetails(with: userInfo)
                    return true
                }
            default: break
            }
        }

        return true
    }
}


// MARK: - Private Helpers
//
private extension InteractiveNotificationsManager {

    /// Likes a comment and marks the associated notification as read
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///
    func likeCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber) {
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
    func approveCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber) {
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
    func showDetailsWithNoteID(_ noteId: NSNumber) {
        WPTabBarController.sharedInstance().showNotificationsTabForNote(withID: noteId.stringValue)
    }


    /// Replies to a comment and marks the associated notification as read
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///     - content: The text for the comment reply
    ///
    func replyToCommentWithCommentID(_ commentID: NSNumber, noteID: NSNumber, siteID: NSNumber, content: String) {
        commentService.replyToComment(withID: commentID, siteID: siteID, content: content, success: {
            self.notificationSyncMediator?.markAsReadAndSync(noteID.stringValue)
            DDLogInfo("Successfully replied comment from push notification")
        }, failure: { error in
            DDLogInfo("Couldn't reply to comment from push notification")
        })
    }


    /// Returns a collection of *UNNotificationCategory* instances, for each one of the
    /// supported NoteCategoryDefinition enum case's.
    ///
    /// - Returns: A set of *UNNotificationCategory* instances.
    ///
    func supportedNotificationCategories() -> Set<UNNotificationCategory> {
        let categories: [UNNotificationCategory] = NoteCategoryDefinition.allDefinitions.map({ $0.notificationCategory() })
        return Set(categories)
    }

    /// Handles approving an 2fa authentication challenge.
    ///
    /// - Parameter userInfo: The notification's Payload
    /// - Returns: True if successfule. Otherwise false.
    ///
    func approveAuthChallenge(_ userInfo: NSDictionary) -> Bool {
        return PushNotificationsManager.shared.handleAuthenticationApprovedAction(userInfo)
    }
}



// MARK: - Nested Types
//
private extension InteractiveNotificationsManager {

    /// Describes information about Custom Actions that WPiOS can perform, as a response to
    /// a Push Notification event.
    ///
    enum NoteCategoryDefinition: String {
        case commentApprove         = "approve-comment"
        case commentLike            = "like-comment"
        case commentReply           = "replyto-comment"
        case commentReplyWithLike   = "replyto-like-comment"
        case mediaUploadSuccess     = "media-upload-success"
        case mediaUploadFailure     = "media-upload-failure"
        case postUploadSuccess      = "post-upload-success"
        case postUploadFailure      = "post-upload-failure"
        case shareUploadSuccess     = "share-upload-success"
        case shareUploadFailure     = "share-upload-failure"
        case login                  = "push_auth"

        var actions: [NoteActionDefinition] {
            switch self {
            case .commentApprove:
                return [.commentApprove]
            case .commentLike:
                return [.commentLike]
            case .commentReply:
                return [.commentReply]
            case .commentReplyWithLike:
                return [.commentReply, .commentLike]
            case .mediaUploadSuccess:
                return [.mediaWritePost]
            case .mediaUploadFailure:
                return [.mediaRetry]
            case .postUploadSuccess:
                return [.postView]
            case .postUploadFailure:
                return [.postRetry]
            case .shareUploadSuccess:
                return [.shareEditPost]
            case .shareUploadFailure:
                return []
            case .login:
                return [.approveLogin, .denyLogin]
            }
        }

        var identifier: String {
            return rawValue
        }

        var isLocalNotification: Bool {
            return NoteCategoryDefinition.localDefinitions.contains(self)
        }

        func notificationCategory() -> UNNotificationCategory {
            return UNNotificationCategory(
                identifier: identifier,
                actions: actions.map({ $0.notificationAction() }),
                intentIdentifiers: [],
                options: [])
        }

        static var allDefinitions = [commentApprove, commentLike, commentReply, commentReplyWithLike, mediaUploadSuccess, mediaUploadFailure, postUploadSuccess, postUploadFailure, shareUploadSuccess, shareUploadFailure, login]
        static var localDefinitions = [mediaUploadSuccess, mediaUploadFailure, postUploadSuccess, postUploadFailure, shareUploadSuccess, shareUploadFailure]
    }



    /// Describes the custom actions that WPiOS can perform in response to a Push notification.
    ///
    enum NoteActionDefinition: String {
        case commentApprove   = "COMMENT_MODERATE_APPROVE"
        case commentLike      = "COMMENT_LIKE"
        case commentReply     = "COMMENT_REPLY"
        case mediaWritePost   = "MEDIA_WRITE_POST"
        case mediaRetry       = "MEDIA_RETRY"
        case postRetry        = "POST_RETRY"
        case postView         = "POST_VIEW"
        case shareEditPost    = "SHARE_EDIT_POST"
        case approveLogin     = "APPROVE_LOGIN_ATTEMPT"
        case denyLogin        = "DENY_LOGIN_ATTEMPT"

        var description: String {
            switch self {
            case .commentApprove:
                return NSLocalizedString("Approve", comment: "Approve comment (verb)")
            case .commentLike:
                return NSLocalizedString("Like", comment: "Like (verb)")
            case .commentReply:
                return NSLocalizedString("Reply", comment: "Reply to a comment (verb)")
            case .mediaWritePost:
                return NSLocalizedString("Write Post", comment: "Opens the editor to write a new post.")
            case .mediaRetry:
                return NSLocalizedString("Retry", comment: "Opens the media library .")
            case .postRetry:
                return NSLocalizedString("Retry", comment: "Retries the upload of a user's post.")
            case .postView:
                return NSLocalizedString("View", comment: "Opens the post epilogue screen to allow sharing / viewing of a post.")
            case .shareEditPost:
                return NSLocalizedString("Edit Post", comment: "Opens the editor to edit an existing post.")
            case .approveLogin:
                return NSLocalizedString("Approve", comment: "Verb. Approves a 2fa authentication challenge, and logs in a user.")
            case .denyLogin:
                return NSLocalizedString("Deny", comment: "Verb. Denies a 2fa authentication challenge.")
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
            switch self {
            case .mediaWritePost, .mediaRetry, .postView, .shareEditPost:
                return true
            default: return false
            }
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
            case .commentReply:
                return UNTextInputNotificationAction(identifier: identifier,
                                                     title: description,
                                                     options: notificationActionOptions,
                                                     textInputButtonTitle: NSLocalizedString("Reply", comment: "Verb. Button title. Reply to a comment."),
                                                     textInputPlaceholder: NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view"))
            default:
                return UNNotificationAction(identifier: identifier, title: description, options: notificationActionOptions)
            }
        }


        /// Quick action analytics support. Returns either a quick action name (if defined) or an empty string.
        /// NB: This maintains parity with Android.
        ///
        var quickActionName: String {
            switch self {
            case .commentApprove:
                return "approve"
            case .commentLike:
                return "like"
            case .commentReply:
                return "reply-to"
            default:
                return ""
            }
        }

        static var allDefinitions = [commentApprove, commentLike, commentReply, mediaWritePost, mediaRetry, postRetry, postView, shareEditPost, approveLogin, denyLogin]
    }
}


// MARK: - UNUserNotificationCenterDelegate Conformance
//
extension InteractiveNotificationsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        let userInfo = notification.request.content.userInfo as NSDictionary

        // If the app is open, and a Zendesk view is being shown, Zendesk will display an alert allowing the user to view the updated ticket.
        handleZendeskNotification(userInfo: userInfo)

        let category = notification.request.content.categoryIdentifier

        guard (category == ShareNoticeConstants.categorySuccessIdentifier || category == ShareNoticeConstants.categoryFailureIdentifier),
            (userInfo.object(forKey: ShareNoticeUserInfoKey.originatedFromAppExtension) as? Bool) == true,
            let postUploadOpID = userInfo.object(forKey: ShareNoticeUserInfoKey.postUploadOpID) as? String  else {
                return
        }

        // If the notification orginated from the share extension, disregard this current notification and resend a new one.
        ShareExtensionSessionManager.fireUserNotificationIfNeeded(postUploadOpID)
        completionHandler([])
    }

    private func handleZendeskNotification(userInfo: NSDictionary) {
        if let type = userInfo.string(forKey: ZendeskUtils.PushNotificationIdentifiers.key),
            type == ZendeskUtils.PushNotificationIdentifiers.type {
            ZendeskUtils.handlePushNotification(userInfo)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        let textInputResponse = response as? UNTextInputNotificationResponse

        // Analytics
        PushNotificationsManager.shared.trackNotification(with: userInfo)

        if handleAction(with: response.actionIdentifier,
                        category: response.notification.request.content.categoryIdentifier,
                        userInfo: userInfo,
                        responseText: textInputResponse?.userText) {
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
        PushNotificationsManager.shared.handleNotification(userInfo, userInteraction: true) { _ in
            completionHandler()
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        MeNavigationAction.notificationSettings.perform()
    }
}
