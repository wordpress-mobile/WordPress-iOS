import Foundation
import AutomatticTracks

final class NotificationsViewModel {
    enum InlineAction: String {
        case sharePost = "share_post"
        case commentLike = "comment_like"
        case postLike = "post_like"
    }

    enum Constants {
        static let lastSeenKey = "notifications_last_seen_time"
        static let headerTextKey = "text"
        static let actionAnalyticsKey = "inline_action"
        static let likedAnalyticsKey = "liked"
    }

    // MARK: - Type Aliases

    typealias ShareablePost = (url: String, title: String?)
    typealias PostReadyForShareCallback = (ShareablePost, IndexPath) -> Void

    // MARK: - Depdencies

    private let contextManager: CoreDataStackSwift
    private let userDefaults: UserPersistentRepository
    private let notificationMediator: NotificationSyncMediatorProtocol?
    private let analyticsTracker: AnalyticsEventTracking.Type
    private let crashLogger: CrashLogging

    // MARK: - Callbacks

    var onPostReadyForShare: PostReadyForShareCallback?

    // MARK: - Init

    init(
        userDefaults: UserPersistentRepository,
        notificationMediator: NotificationSyncMediatorProtocol? = NotificationSyncMediator(),
        contextManager: CoreDataStackSwift = ContextManager.shared,
        analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self,
        crashLogger: CrashLogging = CrashLogging.main
    ) {
        self.userDefaults = userDefaults
        self.notificationMediator = notificationMediator
        self.analyticsTracker = analyticsTracker
        self.crashLogger = crashLogger
        self.contextManager = contextManager
    }

    /// The last time when user seen notifications
    private(set) var lastSeenTime: String? {
        get {
            return userDefaults.string(forKey: Constants.lastSeenKey)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.lastSeenKey)
        }
    }

    func lastSeenChanged(timestamp: String?) {
        guard let timestamp,
              timestamp != lastSeenTime,
              let mediator = notificationMediator else {
            return
        }

        mediator.updateLastSeen(timestamp) { [weak self] error in
            guard error == nil else {
                return
            }

            self?.lastSeenTime = timestamp
        }
    }

    func didChangeDefaultAccount() {
        lastSeenTime = nil
    }

    func loadNotification(
        near note: Notification,
        allNotifications: [Notification],
        withIndexDelta delta: Int
    ) -> Notification? {
        guard let noteIndex = allNotifications.firstIndex(of: note) else {
            return nil
        }

        let targetIndex = noteIndex + delta
        guard targetIndex >= 0 && targetIndex < allNotifications.count else {
            return nil
        }

        func notMatcher(_ note: Notification) -> Bool {
            return note.kind != .matcher
        }

        if delta > 0 {
            return allNotifications
                .suffix(from: targetIndex)
                .first(where: notMatcher)
        } else {
            return allNotifications
                .prefix(through: targetIndex)
                .reversed()
                .first(where: notMatcher)
        }
    }

    // MARK: - Handling Inline Actions

    func sharePostActionTapped(with notification: Notification) -> ShareablePost? {
        guard let url = notification.url else {
            self.crashLogger.logMessage("Failed to share a notification post due to null url", level: .error)
            return nil
        }
        let content: ShareablePost = (
            url: url,
            title: createSharingTitle(from: notification)
        )
        self.trackInlineActionTapped(action: .sharePost)
        return content
    }

    func likeActionTapped(with notification: LikeableNotification,
                          action: InlineAction,
                          changes: @escaping (Bool) -> Void) {
        guard let notificationMediator else {
            return
        }
        // Optimistically update liked status
        var notification = notification
        let oldLikedStatus = notification.liked
        let newLikedStatus = !notification.liked
        changes(newLikedStatus)

        // Update liked status remotely
        let mainContext = contextManager.mainContext
        notification.toggleLike(using: notificationMediator, like: newLikedStatus) { result in
            mainContext.perform {
                do {
                    switch result {
                    case .success(let liked):
                        notification.liked = liked
                        try mainContext.save()
                    case .failure(let error):
                        throw error
                    }
                } catch {
                    changes(oldLikedStatus)
                }
            }
        }

        // Track analytics event
        let properties = [Constants.likedAnalyticsKey: String(newLikedStatus)]
        self.trackInlineActionTapped(action: action, extraProperties: properties)
    }

    // MARK: - Helpers

    private func createSharingTitle(from notification: Notification) -> String {
        guard notification.kind == .like,
              let header = notification.header,
              header.count == 2,
              let titleDictionary = header[1] as? [String: String],
              let postTitle = titleDictionary[Constants.headerTextKey] else {
            crashLogger.logMessage("Failed to extract post title from like notification", level: .info)
            return Strings.sharingMessageWithoutPost
        }
        return String(format: Strings.sharingMessageWithPostFormat, postTitle)
    }
}

// MARK: - Analytics Tracking

private extension NotificationsViewModel {
    func trackInlineActionTapped(action: InlineAction, extraProperties: [AnyHashable: Any] = [:]) {
        var properties: [AnyHashable: Any] = [Constants.actionAnalyticsKey: action.rawValue]
        properties.merge(extraProperties) { current, _ in current }
        self.analyticsTracker.track(.notificationsInlineActionTapped, properties: properties)
    }

    enum Strings {
        static let sharingMessageWithPostFormat = NSLocalizedString("notifications.share.messageWithPost",
                                                                    value: "Check out my post \"%@\":",
                                                                    comment: "Message to use along with the post URL when sharing a post")
        static let sharingMessageWithoutPost = NSLocalizedString("notifications.share.messageWithoutPost",
                                                                       value: "Check out my post:",
                                                                       comment: "Message to use along with the post URL when sharing a post")
    }
}
