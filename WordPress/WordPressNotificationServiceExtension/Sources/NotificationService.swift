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

        let userID = readExtensionUserID()
        tracks.wpcomUserID = userID

        let token = readExtensionToken()
        tracks.trackExtensionLaunched(token != nil)

        guard let notificationContent = self.bestAttemptContent,
            let apsAlert = notificationContent.apsAlert,
            let notificationType = notificationContent.type,
            let notificationKind = NotificationKind(rawValue: notificationType),
            token != nil else {

            let hasToken = token != nil
            tracks.trackNotificationMalformed(hasToken: hasToken, notificationBody: request.content.body)
            contentHandler(request.content)

            return
        }

        guard !NotificationKind.isViewMilestone(notificationKind) else {
            contentHandler(makeViewMilestoneContent(notificationContent))
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

        // If this notification is for 2fa login there won't be a noteID and there
        // is no need to query the notification service. Just return the formatted
        // content.
        if notificationKind == .login {
            let preferredFont = UIFont.preferredFont(forTextStyle: .body)
            let descriptor = preferredFont.fontDescriptor.withSymbolicTraits(.traitBold) ?? preferredFont.fontDescriptor
            let boldFont = UIFont(descriptor: descriptor, size: preferredFont.pointSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: boldFont
            ]

            let viewModel = RichNotificationViewModel(
                attributedBody: NSAttributedString(string: notificationContent.body, attributes: attributes),
                attributedSubject: NSAttributedString(string: notificationContent.title, attributes: attributes),
                gravatarURLString: nil,
                notificationIdentifier: nil,
                notificationReadStatus: true,
                noticon: nil)

            notificationContent.userInfo[CodingUserInfoKey.richNotificationViewModel.rawValue] = viewModel.data
            contentHandler(notificationContent)
            return
        }

        // Make sure we have a noteID before proceeding.
        guard let noteID = notificationContent.noteID else {
            tracks.trackNotificationMalformed(hasToken: true, notificationBody: request.content.body)
            contentHandler(request.content)
            return
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

                // Improve the notification body by trimming whitespace and reducing any multiple blank lines
                notificationContent.body = contentFormatter.body?.condenseWhitespace() ?? ""
            }

            notificationContent.userInfo[CodingUserInfoKey.richNotificationViewModel.rawValue] = viewModel.data

            tracks.trackNotificationAssembled()

            // If the notification contains any image media, download it and attach it to the notification
            guard let mediaURL = contentFormatter.mediaURL else {
                contentHandler(notificationContent)
                return
            }

            self.getMediaAttachment(for: mediaURL) { [weak self] data, fileExtension in
                defer {
                    contentHandler(notificationContent)
                }

                let identifier = UUID().uuidString

                guard
                    let self = self, let data = data, let fileExtension = fileExtension,
                    let fileURL = self.saveMediaAttachment(data: data, fileName: String(format: "%@.%@", identifier, fileExtension))
                else {
                    return
                }

                let imageAttachment = try? UNNotificationAttachment(
                    identifier: identifier,
                    url: fileURL,
                    options: nil)

                if let imageAttachment = imageAttachment {
                    notificationContent.attachments = [imageAttachment]
                }
            }
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

// MARK: - Media Attachment Support
private extension NotificationService {

    /// Attempts to download the image
    /// - Parameters:
    ///   - url: The URL for the image being downloaded
    ///   - completion: Returns the image data and the file extension derived from the returned mime type or nil if the request fails
    private func getMediaAttachment(for url: URL, completion: @escaping (Data?, String?) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        // Allow private images to pulled from WordPress sites.
        if isWPComSite(url: url), let token = self.readExtensionToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("AuthorizationAuthorizationAuthorizationAuthorizationAuthorizationAuthorization")
        }

        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, let mimeType = response?.mimeType else {
                completion(nil, nil)
                return
            }

            let fileExtension: String
            switch mimeType {
            case "image/gif":
                fileExtension = "gif"
            case "image/png":
                fileExtension = "png"
            case "image/jpeg":
                fileExtension = "jpg"
            default:
                fileExtension = "png"
            }

            completion(data, fileExtension)
        }

        task.resume()
    }

    /// Save the downloaded media data with a unique identifier
    /// - Parameters:
    ///   - data: The media attachment data
    ///   - fileName: The filename to use for the file
    /// - Returns: The file URL to the media attachment, or nil if writing failed for any reason
    private func saveMediaAttachment(data: Data, fileName: String) -> URL? {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        let directoryPath = directory.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
            let fileURL = directoryPath.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            return fileURL
        }
        catch {
            return nil
        }
    }

    /// Perform a simple check to see if the URL is a WP.com site
    /// This isn't meant to be extensive and has a few flaws, but since we don't know
    /// much information about the URL and if it's a blog without having to do another request
    /// this works for the current usecases.
    ///
    /// - Parameter url: The URL to check
    /// - Returns: True if it's a WP.com site, False if not.
    private func isWPComSite(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        return host.contains("wordpress.com") || host.contains("wp.com")
    }
}
// MARK: - Keychain support

private extension NotificationService {
    /// Retrieves the WPCOM OAuth Token, meant for Extension usage.
    ///
    /// - Returns: the token if found; `nil` otherwise
    ///
    func readExtensionToken() -> String? {
        guard let oauthToken = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.NotificationsService.keychainTokenKey,
                                                                             andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
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
        guard let username = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.NotificationsService.keychainUsernameKey,
                                                                           andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Service Extension username")
            return nil
        }

        return username
    }

    /// Retrieves the WPCOM userID, meant for Extension usage.
    ///
    /// - Returns: the userID if found; `nil` otherwise
    ///
    func readExtensionUserID() -> String? {
        guard let userID = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.NotificationsService.keychainUserIDKey,
                                                                         andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                                                                         accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Service Extension userID")
            return nil
        }

        return userID
    }
}

// MARK: - View Milestone notifications support
private extension NotificationService {

    func makeViewMilestoneContent(_ content: UNMutableNotificationContent) -> UNNotificationContent {
        content.title = Self.viewMilestoneTitle
        return content
    }

    static let viewMilestoneTitle = AppLocalizedString("You hit a milestone 🚀", comment: "Title for a view milestone push notification")
}
