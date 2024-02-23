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
    private let commentService: CommentService
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
        commentService: CommentService? = nil,
        analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self,
        crashLogger: CrashLogging = CrashLogging.main
    ) {
        self.userDefaults = userDefaults
        self.notificationMediator = notificationMediator
        self.analyticsTracker = analyticsTracker
        self.crashLogger = crashLogger
        self.contextManager = contextManager
        self.readerPostService = readerPostService ?? .init(coreDataStack: contextManager)
        self.commentService = commentService ?? .init(coreDataStack: contextManager)
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
        // Optimistically update liked status
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
        // Optimistically update liked status
        var notification = notification
        let oldLikedStatus = notification.liked
        let newLikedStatus = !notification.liked
        changes(newLikedStatus)

        // Update liked status remotely
        let mainContext = contextManager.mainContext
        self.updateCommentLikeRemotely(notification: notification) { result in
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
        self.trackInlineActionTapped(action: .commentLike)
    }

    private func updatePostLikeRemotely(notification: NewPostNotification, completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
        self.contextManager.performAndSave { context in
            self.updatePostLikeRemotely(notification: notification, in: context, completion: completion)
        }
    }

    private func updateCommentLikeRemotely(notification: CommentNotification, completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
        self.contextManager.performAndSave { context in
            self.updateCommentLikeRemotely(notification: notification, in: context, completion: completion)
        }
    }

    private func updatePostLikeRemotely(notification: NewPostNotification, in context: NSManagedObjectContext, completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
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

    private func updateCommentLikeRemotely(notification: CommentNotification, in context: NSManagedObjectContext, completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
        self.fetchComment(withId: notification.commentID, postID: notification.postID, siteID: notification.siteID, in: context) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let comment):
                self.commentService.toggleLikeStatus(for: comment, siteID: .init(value: notification.siteID)) { liked in
                    completion(.success(liked))
                } failure: { error in
                    completion(.failure(error ?? Error.unknown))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Load Posts & Comments

    private func fetchPost(withId id: UInt, siteID: UInt, in context: NSManagedObjectContext, completion: @escaping (Result<ReaderPost, Swift.Error>) -> Void) {
        // Fetch locally
        if let post = try? ReaderPost.lookup(withID: NSNumber(value: id), forSiteWithID: NSNumber(value: siteID), in: context) {
            completion(.success(post))
            return
        }

        // If not found, then fetch remotely
        self.readerPostService.fetchPost(id, forSite: siteID, isFeed: false) { [weak self] post in
            guard let self else {
                return
            }
            context.perform {
                if let postID = post?.objectID, let post = try? context.existingObject(with: postID) as? ReaderPost {
                    completion(.success(post))
                } else {
                    self.crashLogger.logMessage("Post with ID \(id) is not found", level: .error)
                    completion(.failure(Error.unknown))
                }
            }
        } failure: { error in
            completion(.failure(error ?? Error.unknown))
        }
    }

    private func fetchComment(withId id: UInt, postID: UInt, siteID: UInt, in context: NSManagedObjectContext, completion: @escaping (Result<Comment, Swift.Error>) -> Void) {
        self.fetchPost(withId: postID, siteID: siteID, in: context) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let post):
                // Fetch locally
                let commentID = NSNumber(value: id)
                if let comment = post.comment(withID: commentID) {
                    completion(.success(comment))
                    return
                }

                // Fetch remotely
                self.fetchComment(withId: commentID, post: post, in: context, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchComment(withId id: NSNumber, post: ReaderPost, in context: NSManagedObjectContext, completion: @escaping (Result<Comment, Swift.Error>) -> Void) {
        self.commentService.loadComment(withID: id, for: post, success: { comment in
            context.perform {
                if let commentID = comment?.objectID, let comment = try? context.existingObject(with: commentID) as? Comment {
                    completion(.success(comment))
                } else {
                    self.crashLogger.logMessage("Comment with ID \(id) is not found", level: .error)
                    completion(.failure(Error.unknown))
                }
            }
        }, failure: { error in
            completion(.failure(error ?? Error.unknown))
        })
    }

    // MARK: - Types

    enum Error: Swift.Error {
        case unknown
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
