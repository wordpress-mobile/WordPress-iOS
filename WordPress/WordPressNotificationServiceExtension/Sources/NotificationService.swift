import UserNotifications

import WordPressKit

/// Responsible for enrich the content of designated push notifications.
class NotificationService: UNNotificationServiceExtension {

    // MARK: Properties

    /// Manages analytics calls via Tracks
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    /// The service used to retrieve remote notifications
    private var notificationService: NotificationSyncServiceRemote?

    /// The content handler received from the extension
    private var contentHandler: ((UNNotificationContent) -> Void)?

    /// The pending rich notification content
    private var bestAttemptContent: UNMutableNotificationContent?

    // MARK: UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        let token = readExtensionToken()
        tracks.trackExtensionLaunched(token != nil)

        guard
            let notificationContent = self.bestAttemptContent,
            let apsAlert = notificationContent.apsAlert,
            let noteID = notificationContent.noteID,
            token != nil
        else
        {
            contentHandler(request.content)
            return
        }

        notificationContent.title = apsAlert

        let api = WordPressComRestApi(oAuthToken: token)
        let service = NotificationSyncServiceRemote(wordPressComRestApi: api)
        self.notificationService = service

        service.loadNotes(noteIds: [noteID]) { [tracks] error, notifications in
            if let error = error {
                tracks.trackNotificationRetrievalFailed(notificationIdentifier: noteID, errorDescription: error.localizedDescription)
                return
            }

            guard
                let remoteNotifications = notifications,
                remoteNotifications.count == 1,
                let notification = remoteNotifications.first,
                notification.kind == .comment
            else
            {
                return
            }

            let contentFormatter = RichNotificationContentFormatter(notification: notification)

            guard let bodyText = contentFormatter.formatBody() else { return }
            notificationContent.body = bodyText

            let viewModel = RichNotificationViewModel(
                attributedBody: contentFormatter.formatAttributedBody(),
                attributedSubject: contentFormatter.formatAttributedSubject(),
                gravatarURLString: notification.icon,
                noticon: notification.noticon)
            viewModel.encodeToUserInfo(notificationContent: notificationContent)

            tracks.trackNotificationAssembled()

            contentHandler(notificationContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        notificationService?.wordPressComRestApi.invalidateAndCancelTasks()

        if let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent {

            contentHandler(bestAttemptContent)
        }
    }

    // MARK: Private behavior

    /// Retrieves the WPCOM OAuth Token, meant for Extension usage.
    ///
    /// - Returns: the token if found; `nil` otherwise
    ///
    private func readExtensionToken() -> String? {
        guard
            let oauthToken = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationServiceExtensionKeychainTokenKey,
                                                                           andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup)
        else
        {
            debugPrint("Unable to retrieve Notification Service Extension OAuth token")
            return nil
        }

        return oauthToken
    }
}
