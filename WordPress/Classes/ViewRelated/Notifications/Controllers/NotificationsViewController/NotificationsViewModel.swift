import Foundation
import AutomatticTracks

final class NotificationsViewModel {
    enum Constants {
        static let lastSeenKey = "notifications_last_seen_time"
    }

    // MARK: - Type Aliases

    typealias ShareablePost = (url: String, title: String?)
    typealias PostReadyForShareCallback = (ShareablePost, IndexPath) -> Void

    // MARK: - Depdencies

    private let contextManager: CoreDataStackSwift
    private let readerPostService: ReaderPostService
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
        readerPostService: ReaderPostService? = nil,
        analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self,
        crashLogger: CrashLogging = CrashLogging.main
    ) {
        self.userDefaults = userDefaults
        self.notificationMediator = notificationMediator
        self.analyticsTracker = analyticsTracker
        self.crashLogger = crashLogger
        self.contextManager = contextManager
        self.readerPostService = readerPostService ?? .init(coreDataStack: contextManager)
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
            title: notification.title
        )
        self.trackInlineActionTapped(action: .sharePost)
        return content
    }

    func postLikeActionTapped(with notification: NewPostNotification, changes: @escaping (Bool) -> Void) {
        // Optimisitcally update liked status
        var notification = notification
        let oldLikedStatus = notification.liked
        let newLikedStatus = !notification.liked
        changes(newLikedStatus)

        // Update liked status remotely
        let mainContext = contextManager.mainContext
        self.updatePostLikeRemotely(notification: notification) { result in
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
        self.trackInlineActionTapped(action: .postLike)
    }

    func commentLikeActionTapped(with notification: CommentNotification, changes: @escaping (Bool) -> Void) {
        // Optimisitcally update liked status
        var notification = notification
        let oldLikedStatus = notification.liked
        let newLikedStatus = !notification.liked
        changes(newLikedStatus)

        // Update liked status remotely
        notification.liked = newLikedStatus
//        let mainContext = contextManager.mainContext
//        self.updatePostLikeRemotely(notification: notification) { result in
//            mainContext.perform {
//                do {
//                    switch result {
//                    case .success(let liked):
//                        notification.liked = liked
//                        try mainContext.save()
//                    case .failure(let error):
//                        throw error
//                    }
//                } catch {
//                    changes(oldLikedStatus)
//                }
//            }
//        }

        // Track analytics event
        self.trackInlineActionTapped(action: .commentLike)
    }

    private func updatePostLikeRemotely(notification: NewPostNotification, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.contextManager.performAndSave { context in
            self.updatePostLikeRemotely(notification: notification, in: context, completion: completion)
        }
    }

    private func updatePostLikeRemotely(notification: NewPostNotification, in context: NSManagedObjectContext, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.fetchPost(withId: notification.postID, siteID: notification.siteID, in: context) { result in
            switch result {
            case .success(let post):
                let action = ReaderLikeAction(service: self.readerPostService)
                action.execute(with: post) { result in
                    completion(result)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Load Posts & Comments

    private func fetchPost(withId id: UInt, siteID: UInt, in context: NSManagedObjectContext, completion: @escaping (Result<ReaderPost, Error>) -> Void) {
        // Fetch locally
        if let post = try? ReaderPost.lookup(withID: NSNumber(value: id), forSiteWithID: NSNumber(value: siteID), in: context) {
            completion(.success(post))
            return
        }

        // If not found, then fetch remotely
        let unknownError = NSError(domain: "\(NotificationsViewModel.self)", code: -1, userInfo: nil)
        self.readerPostService.fetchPost(id, forSite: siteID, isFeed: false) { [weak self] post in
            guard let self else {
                return
            }
            if let post {
                completion(.success(post))
            } else {
                self.crashLogger.logMessage("Post with ID \(id) is not found", level: .error)
                completion(.failure(unknownError))
            }
        } failure: { error in
            completion(.failure(error ?? unknownError))
        }
    }
}

// MARK: - Analytics Tracking

private extension NotificationsViewModel {

    func trackInlineActionTapped(action: InlineAction) {
        self.analyticsTracker.track(.notificationsInlineActionTapped, properties: ["inline_action": action.rawValue])
    }

    enum InlineAction: String {
        case sharePost = "share_post"
        case commentLike = "comment_like"
        case postLike = "post_like"
    }
}
