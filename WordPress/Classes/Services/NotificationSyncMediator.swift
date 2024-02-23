import Foundation
import CocoaLumberjack
import WordPressKit

/// Notes:
///
/// You may have noticed this is a *Mediator*, not a service. Reason we're adopting a different name here,
/// briefly, is because this entity needs to be aware of other instances, in order to successfully
/// prevent race conditions / data duplication.
///
/// IE multiple SyncService's running concurrently, with no shared MOC / Locks, may end up retrieving and
/// inserting the same set of notifications. Which leads to loss of data integrity.
///
/// Details in #6220.
///

// MARK: - Notifications
//
let NotificationSyncMediatorDidUpdateNotifications = "NotificationSyncMediatorDidUpdateNotifications"

protocol NotificationSyncMediatorProtocol {
    func updateLastSeen(_ timestamp: String, completion: ((Error?) -> Void)?)
    func toggleLikeForPostNotification(like: Bool,
                                       postID: UInt,
                                       siteID: UInt,
                                       completion: @escaping (Result<Bool, Swift.Error>) -> Void)
    func toggleLikeForCommentNotification(like: Bool,
                                          commentID: UInt,
                                          siteID: UInt,
                                          completion: @escaping (Result<Bool, Swift.Error>) -> Void)
}

// MARK: - NotificationSyncMediator
//
final class NotificationSyncMediator: NotificationSyncMediatorProtocol {
    /// Returns the Main Managed Context
    ///
    private let contextManager: CoreDataStackSwift

    /// API object used to make network requests
    /// Used by remote services
    ///
    fileprivate let restAPI: WordPressComRestApi

    /// Sync Service Remote
    ///
    fileprivate let remote: NotificationSyncServiceRemote

    /// Reader Service Remote
    /// Used for toggling like status for posts and comments
    ///
    fileprivate let readerRemoteService: ReaderPostServiceRemote

    /// Comment Remote Factory
    /// Used to create a comment remote service by providing a siteID and restAPI
    fileprivate let commentRemoteFactory: CommentServiceRemoteFactory

    /// Maximum number of Notes to Sync
    ///
    fileprivate let maximumNotes = 100

    /// Main CoreData Context
    ///
    fileprivate var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

    /// Shared serial operation queue among all instances.
    ///
    /// This queue is used to ensure notification operations (like syncing operations) invoked from various places of
    /// the app are performed sequentially, to prevent potential data corruption.
    private static let operationQueue = {
        let queue = OperationQueue()
        queue.name = "org.wordpress.NotificationSyncMediator"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// Designed Initializer
    ///
    convenience init?() {
        let manager = ContextManager.sharedInstance()

        guard let dotcomAPI = try? WPAccount.lookupDefaultWordPressComAccount(in: manager.mainContext)?.wordPressComRestApi else {
            return nil
        }

        self.init(manager: manager, dotcomAPI: dotcomAPI)
    }

    /// Initializer: Useful for Unit Testing
    ///
    /// - Parameters:
    ///     - manager: ContextManager Instance
    ///     - wordPressComRestApi: The WordPressComRestApi that should be used.
    ///
    init?(manager: CoreDataStackSwift, dotcomAPI: WordPressComRestApi) {
        guard dotcomAPI.hasCredentials() else {
            return nil
        }

        contextManager = manager
        restAPI = dotcomAPI
        remote = NotificationSyncServiceRemote(wordPressComRestApi: restAPI)
        readerRemoteService = ReaderPostServiceRemote(wordPressComRestApi: restAPI)
        commentRemoteFactory = CommentServiceRemoteFactory()
    }

    /// Syncs the latest *maximumNotes*:
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Latest 100 hashes are retrieved (++efficiency++)
    /// - Only those Notifications that were remotely changed (Updated / Inserted) will be retrieved
    /// - Local collection will be updated. Old notes will be purged!
    ///
    func sync(_ completion: ((Error?, Bool) -> Void)? = nil) {
        assert(Thread.isMainThread)

        remote.loadHashes(withPageSize: maximumNotes) { error, remoteHashes in
            guard let remoteHashes = remoteHashes else {
                completion?(error, false)
                return
            }

            self.deleteLocalMissingNotes(from: remoteHashes) {

                self.determineUpdatedNotes(with: remoteHashes) { outdatedNoteIds in
                    guard outdatedNoteIds.isEmpty == false else {
                        completion?(nil, false)
                        return
                    }

                    self.remote.loadNotes(noteIds: outdatedNoteIds) { error, remoteNotes in
                        guard let remoteNotes = remoteNotes else {
                            completion?(error, false)
                            return
                        }

                        self.updateLocalNotes(with: remoteNotes) {
                            self.notifyNotificationsWereUpdated()
                            completion?(nil, true)
                        }
                    }
                }
            }
        }
    }

    /// Sync's Notification matching the specified ID, and updates the local entity.
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - noteId: Notification ID of the note to be downloaded.
    ///     - completion: Closure to be executed on completion.
    ///
    func syncNote(with noteId: String, completion: ((Error?, Notification?) -> Void)? = nil) {
        assert(Thread.isMainThread)

        remote.loadNotes(noteIds: [noteId]) { error, remoteNotes in
            guard let remoteNotes = remoteNotes else {
                completion?(error, nil)
                return
            }

            self.updateLocalNotes(with: remoteNotes) {
                let predicate = NSPredicate(format: "(notificationId == %@)", noteId)
                let note = self.mainContext.firstObject(ofType: Notification.self, matching: predicate)

                completion?(nil, note)
            }
        }
    }

    /// Marks a Notification as Read.
    ///
    /// - Note: This method is called on the main thread.
    ///
    /// - Parameters:
    ///     - notification: The notification that was just read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsRead(_ notification: Notification, completion: ((Error?)-> Void)? = nil) {
        Task { @MainActor in
            mark([notification], asRead: true, completion: completion)
        }
    }

    /// Marks an array of notifications as Read.
    ///
    /// - Note: This method is called on the main thread.
    ///
    /// - Parameters:
    ///     - notifications: Notifications that were marked as read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsRead(_ notifications: [Notification], completion: ((Error?)-> Void)? = nil) {
        Task { @MainActor in
            mark(notifications, asRead: true, completion: completion)
        }
    }

    /// Marks a Notification as Unead.
    ///
    /// - Note: This method is called on the main thread.
    ///
    /// - Parameters:
    ///     - notification: The notification that should be marked unread.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsUnread(_ notification: Notification, completion: ((Error?)-> Void)? = nil) {
        markAsUnread([notification], completion: completion)
    }

    /// Marks a Notification as Unread.
    ///
    /// - Note: This method is called on the main thread.
    ///
    /// - Parameters:
    ///     - notifications: The notifications that should be marked unread.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsUnread(_ notifications: [Notification], completion: ((Error?)-> Void)? = nil) {
        Task { @MainActor in
            mark(notifications, asRead: false, completion: completion)
        }
    }

    @MainActor private func mark(_ notifications: [Notification], asRead read: Bool = true, completion: ((Error?)-> Void)? = nil) {
        let noteIDs = notifications.map {
            $0.notificationId
        }

        remote.updateReadStatusForNotifications(noteIDs, read: read) { error in
            if let error = error {
                DDLogError("Error marking notifications as \(Self.readState(for: read)): \(error)")
                // Ideally, we'd want to revert to the previous status if this
                // fails, but if the note is visible, the UI layer will keep
                // trying to mark this note and fail.
                //
                // While not a perfect UX, the easy way out is to pretend it
                // worked, but invalidate the cache so it can be reverted in the
                // next successful sync.
                //
                // https://github.com/wordpress-mobile/WordPress-iOS/issues/7216
                NotificationSyncMediator()?.invalidateCacheForNotifications(noteIDs)
            }

            completion?(error)
        }

        let objectIDs = notifications.map {
            $0.objectID
        }

        updateReadStatus(
            read,
            forNotesWithObjectIDs: objectIDs
        )
    }

    private static func readState(for read: Bool) -> String {
        read ? "read" : "unread"
    }

    /// Invalidates the cache for a notification, marks it as read and syncs it.
    ///
    /// - Parameters:
    ///     - noteID: The notification id to mark as read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsReadAndSync(_ noteID: String, completion: ((Error?) -> Void)? = nil) {
        invalidateCacheForNotification(noteID)
        remote.updateReadStatus(noteID, read: true) { error in
            if let error = error {
                DDLogError("Error marking note as read: \(error)")
            }
            self.syncNote(with: noteID) { (_, _) in
                completion?(error)
            }
        }
    }

    /// Updates the Backend's Last Seen Timestamp. Used to calculate the Badge Count!
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - timestamp: Timestamp of the last seen notification.
    ///     - completion: Callback to be executed on completion.
    ///
    func updateLastSeen(_ timestamp: String, completion: ((Error?) -> Void)? = nil) {
        assert(Thread.isMainThread)

        remote.updateLastSeen(timestamp) { error in
            if let error = error {
                DDLogError("Error while Updating Last Seen Timestamp: \(error)")
            }

            completion?(error)
        }
    }

    /// Deletes the note with the given ID from Core Data.
    ///
    func deleteNote(noteID: String) {
        Self.operationQueue.addOperation(AsyncBlockOperation { [contextManager] done in
            contextManager.performAndSave({ context in
                let predicate = NSPredicate(format: "(notificationId == %@)", noteID)

                for orphan in context.allObjects(ofType: Notification.self, matching: predicate) {
                    context.deleteObject(orphan)
                }
            }, completion: done, on: .main)
        })
    }

    /// Invalidates the local cache for the notification with the specified ID.
    ///
    func invalidateCacheForNotification(_ noteID: String) {
        invalidateCacheForNotifications([noteID])
    }

    /// Invalidates the local cache for all the notifications with specified ID's in the array.
    ///
    func invalidateCacheForNotifications(_ noteIDs: [String]) {
        Self.operationQueue.addOperation(AsyncBlockOperation { [contextManager] done in
            contextManager.performAndSave({ context in
                let predicate = NSPredicate(format: "(notificationId IN %@)", noteIDs)
                let notifications = context.allObjects(ofType: Notification.self, matching: predicate)

                notifications.forEach { $0.notificationHash = nil }
            }, completion: done, on: .main)
        })
    }

    func toggleLikeForPostNotification(like: Bool,
                                       postID: UInt,
                                       siteID: UInt,
                                       completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
        if like {
            readerRemoteService.likePost(postID, forSite: siteID) {
                completion(.success(like))
            } failure: { error in
                completion(.failure(error ?? ServiceError.unknown))
            }
        } else {
            readerRemoteService.unlikePost(postID, forSite: siteID) {
                completion(.success(like))
            } failure: { error in
                completion(.failure(error ?? ServiceError.unknown))
            }
        }
    }

    func toggleLikeForCommentNotification(like: Bool,
                                          commentID: UInt,
                                          siteID: UInt,
                                          completion: @escaping (Result<Bool, Swift.Error>) -> Void) {
        let commentService = commentRemoteFactory.restRemote(siteID: NSNumber(value: siteID), api: restAPI)
        if like {
            commentService.likeComment(withID: NSNumber(value: commentID)) {
                completion(.success(like))
            } failure: { error in
                completion(.failure(error ?? ServiceError.unknown))
            }
        } else {
            commentService.unlikeComment(withID: NSNumber(value: commentID)) {
                completion(.success(like))
            } failure: { error in
                completion(.failure(error ?? ServiceError.unknown))
            }
        }
    }
}

// MARK: - Private Helpers
//
private extension NotificationSyncMediator {
    /// Given a collection of RemoteNotification Hashes, this method will determine the NotificationID's
    /// that are either missing in our database, or have been remotely updated.
    ///
    /// - Parameters:
    ///     - remoteHashes: Collection of Notification Hashes
    ///     - completion: Callback to be executed on completion
    ///
    func determineUpdatedNotes(with remoteHashes: [RemoteNotification], completion: @escaping (([String]) -> Void)) {
        Self.operationQueue.addOperation(AsyncBlockOperation { [contextManager] done in
            contextManager.performAndSave({ context in
                let remoteIds = remoteHashes.map { $0.notificationId }
                let predicate = NSPredicate(format: "(notificationId IN %@)", remoteIds)
                var localHashes = [String: String]()

                for note in context.allObjects(ofType: Notification.self, matching: predicate) {
                    localHashes[note.notificationId] = note.notificationHash ?? ""
                }

                return remoteHashes
                    .filter { remote in
                        let localHash = localHashes[remote.notificationId]
                        return localHash == nil || localHash != remote.notificationHash
                    }
                    .map { $0.notificationId }
            }, completion: { outdatedIds in
                completion(outdatedIds)
                done()
            }, on: .main)
        })
    }

    /// Given a collection of remoteNotes, this method will insert missing local ones, and update the ones
    /// that can be found.
    ///
    /// - Parameters:
    ///     - remoteNotes: Collection of Remote Notes
    ///     - completion: Callback to be executed on completion
    ///
    func updateLocalNotes(with remoteNotes: [RemoteNotification], completion: (() -> Void)? = nil) {
        Self.operationQueue.addOperation(AsyncBlockOperation { [contextManager] done in
            contextManager.performAndSave({ context in
                for remoteNote in remoteNotes {
                    let predicate = NSPredicate(format: "(notificationId == %@)", remoteNote.notificationId)
                    let localNote = context.firstObject(ofType: Notification.self, matching: predicate) ?? context.insertNewObject(ofType: Notification.self)

                    localNote.update(with: remoteNote)
                }
            }, completion: {
                done()
                DispatchQueue.main.async {
                    completion?()
                }
            }, on: .global())
        })
    }

    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteHashes: Collection of remoteNotifications.
    ///
    func deleteLocalMissingNotes(from remoteHashes: [RemoteNotification], completion: @escaping (() -> Void)) {
        Self.operationQueue.addOperation(AsyncBlockOperation { [contextManager] done in
            contextManager.performAndSave({ context in
                let remoteIds = remoteHashes.map { $0.notificationId }
                let predicate = NSPredicate(format: "NOT (notificationId IN %@)", remoteIds)

                for orphan in context.allObjects(ofType: Notification.self, matching: predicate) {
                    context.deleteObject(orphan)
                }
            }, completion: {
                done()
                DispatchQueue.main.async {
                    completion()
                }
            }, on: .global())
        })
    }

    /// Updates the Read status, of a given Notification, as specified.
    ///
    /// Note: This method uses *saveContextAndWait* in order to prevent animation glitches when pushing
    /// Notification Details.
    ///
    /// - Parameters:
    ///     - status: New *read* value
    ///     - noteObjectID: CoreData ObjectID
    ///
    func updateReadStatus(_ status: Bool, forNoteWithObjectID noteObjectID: NSManagedObjectID) {
        updateReadStatus(status, forNotesWithObjectIDs: [noteObjectID])
    }

    /// Updates the Read status, of an array of Notifications, as specified.
    ///
    /// Note: This method uses *saveContextAndWait* in order to prevent animation glitches when pushing
    /// Notification Details.
    ///
    /// - Parameters:
    ///     - status: New *read* value
    ///     - notesObjectIDs: CoreData ObjectIDs
    ///
    func updateReadStatus(_ status: Bool, forNotesWithObjectIDs notesObjectIDs: [NSManagedObjectID]) {
        let predicate = NSPredicate(format: "SELF IN %@", notesObjectIDs)

        let notes = mainContext.allObjects(ofType: Notification.self, matching: predicate)

        notes.forEach { $0.read = status }
        contextManager.saveContextAndWait(mainContext)
    }

    /// Posts a `NotificationSyncMediatorDidUpdateNotifications` Notification, so that (potential listeners)
    /// may react upon new content.
    ///
    func notifyNotificationsWereUpdated() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Foundation.Notification.Name(rawValue: NotificationSyncMediatorDidUpdateNotifications), object: nil)
    }
}

extension NotificationSyncMediator {

    enum ServiceError: Error {
        case unknown
    }
}
