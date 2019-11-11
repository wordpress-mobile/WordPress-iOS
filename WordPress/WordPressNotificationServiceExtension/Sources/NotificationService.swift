import UserNotifications

import WordPressKit

// MARK: - NotificationService

/// Responsible for enrich the content of designated push notifications.
class NotificationService: UNNotificationServiceExtension {

    // MARK: Properties

    /// Manages analytics calls via Tracks
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    /// The content handler received from the extension
    private var contentHandler: ((UNNotificationContent) -> Void)?

    /// The pending rich notification content
    private var bestAttemptContent: UNMutableNotificationContent?

    /// The service used to retrieve remote notifications
    private var notificationService: NotificationSyncServiceRemote?

    // MARK: UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        let username = readExtensionUsername()
        tracks.wpcomUsername = username

        let token = readExtensionToken()
        tracks.trackExtensionLaunched(token != nil)

        guard let notificationContent = self.bestAttemptContent,
            let apsAlert = notificationContent.apsAlert,
            let noteID = notificationContent.noteID,
            let notificationType = notificationContent.type,
            let notificationKind = NotificationKind(rawValue: notificationType),
            token != nil else {
            tracks.trackNotificationMalformed(properties: ["have_token": (token != nil) as AnyObject,
                                                           "content": request.content])
            contentHandler(request.content)

            return
        }

        guard NotificationKind.isSupportedByRichNotifications(notificationKind) else {
            tracks.trackNotificationDiscarded(notificationType: notificationType)

            contentHandler(notificationContent)
            return
        }

        if let category = notificationKind.contentExtensionCategoryIdentifier {
            notificationContent.categoryIdentifier = category
        }

        // If the notification has a body but not a title, and is a notification
        // type that _can_ have a separate title and body, in case of failure later
        // for now let's just populate the title with what we have.
        // In practice, this means that notifications other than likes and
        // comment likes will always have a bolded title.
        if notificationContent.title.isEmpty,
            !notificationContent.body.isEmpty,
            !NotificationKind.omitsRichNotificationBody(notificationKind) {
            notificationContent.title = notificationContent.body
            notificationContent.body = ""
        }

        let api = WordPressComRestApi(oAuthToken: token)
        let service = NotificationSyncServiceRemote(wordPressComRestApi: api)
        self.notificationService = service

        service.loadNotes(noteIds: [noteID]) { [tracks] error, notifications in
            if let error = error {
                tracks.trackNotificationRetrievalFailed(notificationIdentifier: noteID, errorDescription: error.localizedDescription)
                contentHandler(notificationContent)
                return
            }

            guard let remoteNotifications = notifications,
                remoteNotifications.count == 1,
                let notification = remoteNotifications.first else {
                contentHandler(notificationContent)
                return
            }

            let contentFormatter = RichNotificationContentFormatter(notification: notification)

            let viewModel = RichNotificationViewModel(
                attributedBody: contentFormatter.attributedBody,
                attributedSubject: contentFormatter.attributedSubject,
                gravatarURLString: notification.icon,
                notificationIdentifier: notification.notificationId,
                notificationReadStatus: notification.read,
                noticon: notification.noticon)

            // Only populate title / body for notification kinds with rich body content
            if !NotificationKind.omitsRichNotificationBody(notificationKind) {
                notificationContent.title = contentFormatter.attributedSubject?.string ?? apsAlert
                notificationContent.body = contentFormatter.body ?? ""
            }
            notificationContent.userInfo[CodingUserInfoKey.richNotificationViewModel.rawValue] = viewModel.data

            tracks.trackNotificationAssembled()

            contentHandler(notificationContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        tracks.trackNotificationTimedOut()

        notificationService?.wordPressComRestApi.invalidateAndCancelTasks()

        if let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent {

            contentHandler(bestAttemptContent)
        }
    }
}

// MARK: - Keychain support

private extension NotificationService {
    /// Retrieves the WPCOM OAuth Token, meant for Extension usage.
    ///
    /// - Returns: the token if found; `nil` otherwise
    ///
    func readExtensionToken() -> String? {
        guard let oauthToken = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationServiceExtensionKeychainTokenKey,
                                                                             andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                                             accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Service Extension OAuth token")
            return nil
        }

        return oauthToken
    }

    /// Retrieves the WPCOM username, meant for Extension usage.
    ///
    /// - Returns: the username if found; `nil` otherwise
    ///
    func readExtensionUsername() -> String? {
        guard let username = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationServiceExtensionKeychainUsernameKey,
                                                                           andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Service Extension username")
            return nil
        }

        return username
    }
}
