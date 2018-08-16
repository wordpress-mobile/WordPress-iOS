import UserNotifications

import WordPressKit

class NotificationService: UNNotificationServiceExtension {

    // MARK: Properties

    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private var notificationService: NotificationSyncServiceRemote?

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    // MARK: UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        let token = readExtensionToken()
        tracks.trackExtensionLaunched(token != nil)

        guard
            let notificationContent = self.bestAttemptContent,
            let noteID = notificationContent.userInfo["note_id"] as? Int,
            let aps = notificationContent.userInfo["aps"] as? NSDictionary,
            let apsAlert = aps["alert"] as? String,
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

        let identifiers = [ String(noteID) ]
        service.loadNotes(noteIds: identifiers) { [tracks] error, notifications in
            defer {
                contentHandler(notificationContent)
            }

            if let error = error {
                tracks.trackNotificationRetrievalFailed(notificationIdentifier: noteID, errorDescription: error.localizedDescription)
                return
            }

            if let remoteNotifications = notifications,
                remoteNotifications.count == 1,
                let notification = remoteNotifications.first,
                notification.kind == .comment,
                let body = notification.body,
                let bodyBlocks = body as? [[String: AnyObject]] {

                let parser = RemoteNotificationActionParser()
                let blocks = NotificationContentFactory.content(
                    from: bodyBlocks,
                    actionsParser: parser,
                    parent: notification)

                if let comment: FormattableCommentContent = FormattableContentGroup.blockOfKind(.comment, from: blocks),
                    let notificationText = comment.text,
                    !notificationText.isEmpty {

                    notificationContent.body = notificationText
                }

                // NB: placeholder pending `note_type`
                let placeholderNoteType = "replyto-like-comment"
                notificationContent.categoryIdentifier = placeholderNoteType

                tracks.trackNotificationAssembled()
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        notificationService?.wordPressComRestApi.invalidateAndCancelTasks()

        if let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent {

            contentHandler(bestAttemptContent)
        }
    }
}

private extension NotificationService {
    /// Retrieves the WPCOM OAuth Token, meant for Extension usage.
    ///
    /// - Returns: the token if found; `nil` otherwise
    ///
    func readExtensionToken() -> String? {
        guard
            let oauthToken = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationServiceExtensionKeychainTokenKey,
                                                                           andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup)
            else {
                debugPrint("Unable to retrieve Notification Service Extension OAuth token")
                return nil
        }

        return oauthToken
    }
}
