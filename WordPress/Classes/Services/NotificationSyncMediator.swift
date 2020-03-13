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


// MARK: - NotificationSyncMediator
//
class NotificationSyncMediator {
    /// Returns the Main Managed Context
    ///
    fileprivate let contextManager: ContextManager

    /// Sync Service Remote
    ///
    fileprivate let remote: NotificationSyncServiceRemote

    /// Maximum number of Notes to Sync
    ///
    fileprivate let maximumNotes = 100

    /// Main CoreData Context
    ///
    fileprivate var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

    /// Thread Safety Helper!
    ///
    fileprivate static let lock = NSLock()

    /// Shared PrivateContext among all of the Sync Service Instances
    ///
    fileprivate static var privateContext: NSManagedObjectContext!



    /// Designed Initializer
    ///
    convenience init?() {
        let manager = ContextManager.sharedInstance()
        let service = AccountService(managedObjectContext: manager.mainContext)

        guard let dotcomAPI = service.defaultWordPressComAccount()?.wordPressComRestApi else {
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
    init?(manager: ContextManager, dotcomAPI: WordPressComRestApi) {
        guard dotcomAPI.hasCredentials() else {
            return nil
        }

        contextManager = manager
        remote = NotificationSyncServiceRemote(wordPressComRestApi: dotcomAPI)
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

            let hackedHashes = [
                RemoteNotification(document: [
                    "id": 1234,
                    "note_hash": 9999999
                    ] as [String: AnyObject] )!
            ]

            self.deleteLocalMissingNotes(from: hackedHashes) {

                self.determineUpdatedNotes(with: remoteHashes) { outdatedNoteIds in
                    guard outdatedNoteIds.isEmpty == false else {
                        completion?(nil, false)
                        return
                    }

                    self.remote.loadNotes(noteIds: outdatedNoteIds) { error, remoteNotes in
let hackedNotes = [
    RemoteNotification(document: [
        "id": 1234,
        "note_hash": 1234,
        "type": "comment",
        "read": 1,
        "noticon": "\u{f814}",
        "timestamp": "2020-03-05T09:06:52+00:00",
        "icon": "https:\\/\\/1.gravatar.com",
        "url": "https:\\/\\/something",
        "subject": [[
            "text": "Aaaaa Aaaaaa mentioned you on I created a simple...",
            "ranges": [[
                "type": "noticon",
                "indices": [0, 0],
                "value": "\u{f467}"
            ], [
                "type": "user",
                "indices": [0, 12],
                "url": "http:\\/\\/aaaaaaa.com",
                "site_id": 999999999999,
                "id": 999999999999
            ], [
                "type": "post",
                "indices": [30, 51],
                "url": "https:\\/\\/something",
                "site_id": 999999999999,
                "id": 999999999999
            ]]
        ], [
            "text": "I just deployed an update of the IIII service that will check if sssss for a commit were really generated before using them to calculate a delta.\\nUntil now, the select from stats SQL \\u2026\\n",
            "ranges": [[
                "type": "comment",
                "indices": [0, 185],
                "url": "https:\\/\\/something",
                "site_id": 999999999999,
                "post_id": 999999999999,
                "id": 999999999999
            ]]
        ]],
        "body": [[
            "text": "Aaaaa Aaaaaa",
            "ranges": [[
                "email": "test@test.com",
                "url": "http:\\/\\/something",
                "id": 999999999999,
                "site_id": 999999999999,
                "type": "user",
                "indices": [0, 12]
            ]],
            "media": [[
                "type": "image",
                "indices": [0, 0],
                "height": "256",
                "width": "256",
                "url": "https:\\/\\/1.gravatar.com\\/avatar"
            ]],
            "actions": [
                "follow": false
            ],
            "meta": [
                "links": [
                ],
                "ids": [
                    "user": 999999999999,
                    "site": 999999999999
                ],
                "titles": [
                    "home": "Aaaaa Aaaaaa"
                ]
            ],
            "type": "user"
        ], [
            "text": "I just deployed an update of the IIII sssssss that will check if stats for a commit were really generated before using them to calculate a delta.\n\nUntil now, the select from sssss SQL query simply returned zzzz rows, making one side of the delta empty.\n\nIf the needed stats are not available, xxxx will not proceed to post a comment.\n\nThis is a simple fix that I\u{2019}ve procrastinating on for too long. But now when we\u{2019}re having a lot of issues with unstable CI builds, the problem started happening much more often. Thanks @wwwww for callint it out 👍",
            "ranges": [[
                "url": "https:\\/\\/something/",
                "indices": [520, 526]
            ], [
                "type": "code",
                "indices": [162, 179]
            ]],
            "actions": [
                "spam-comment": false,
                "trash-comment": false,
                "approve-comment": true,
                "edit-comment": false,
                "replyto-comment": true,
                "like-comment": false
            ],
            "meta": [
                "ids": [
                    "comment": 999999999999,
                    "user": 999999999999,
                    "post": 999999999999,
                    "site": 999999999999
                ],
                "links": []
            ],
            "type": "comment",
            "nest_level": 0,
        ], [
            "text": "You replied to this comment.",
            "ranges": [[
                "type": "noticon",
                "indices": [0, 0],
                "value": "\u{f467}"
            ], [
                "type": "comment",
                "indices": [4, 11],
                "url": "https:\\/\\/something",
                "site_id": 999999999999,
                "post_id": 999999999999,
                "id": 999999999999
            ]]
        ]],
        "meta": [
            "ids": [
                "user": 999999999999,
                "comment": 999999999999,
                "post": 999999999999,
                "site": 999999999999,
                "reply_comment": 999999999999
            ],
            "links": [
            ]
        ],
        "header": [[
            "text": "Aaaaa Aaaaaaaa",
            "ranges": [[
                "type": "user",
                "indices": [0, 14],
                "url": "http:\\/\\/aaaaaaa\\/",
                "site_id": 999999999999,
                "id": 999999999999
            ]],
            "media": [[
                "type": "image",
                "indices": [0, 0],
                "height": "256",
                "width": "256",
                "url": "https:\\/\\/2.gravatar.com"
            ]]
        ], [
            "text": "I created a simple..."
        ]],
        "title": "Mention"
    ] as [String: AnyObject])!
]
                        self.updateLocalNotes(with: hackedNotes) {
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
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - notification: The notification that was just read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsRead(_ notification: Notification, completion: ((Error?)-> Void)? = nil) {
        mark(notification, asRead: true, completion: completion)
    }

    /// Marks a Notification as Unead.
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - notification: The notification that should be marked unread.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsUnread(_ notification: Notification, completion: ((Error?)-> Void)? = nil) {
        mark(notification, asRead: false, completion: completion)
    }

    private func mark(_ notification: Notification, asRead read: Bool = true, completion: ((Error?)-> Void)? = nil) {
        assert(Thread.isMainThread)

        let noteID = notification.notificationId
        remote.updateReadStatus(noteID, read: read) { error in
            if let error = error {
                let readState = read ? "read" : "unread"
                DDLogError("Error marking note as \(readState): \(error)")
                // Ideally, we'd want to revert to the previous status if this
                // fails, but if the note is visible, the UI layer will keep
                // trying to mark this note and fail.
                //
                // While not a perfect UX, the easy way out is to pretend it
                // worked, but invalidate the cache so it can be reverted in the
                // next successful sync.
                //
                // https://github.com/wordpress-mobile/WordPress-iOS/issues/7216
                NotificationSyncMediator()?.invalidateCacheForNotification(with: noteID)
            }

            completion?(error)
        }

        updateReadStatus(read, forNoteWithObjectID: notification.objectID)
    }

    /// Invalidates the cache for a notification, marks it as read and syncs it.
    ///
    /// - Parameters:
    ///     - noteID: The notification id to mark as read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsReadAndSync(_ noteID: String, completion: ((Error?) -> Void)? = nil) {
        invalidateCacheForNotification(with: noteID)
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
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)

        derivedContext.perform {
            let predicate = NSPredicate(format: "(notificationId == %@)", noteID)

            for orphan in derivedContext.allObjects(ofType: Notification.self, matching: predicate) {
                derivedContext.deleteObject(orphan)
            }

            self.contextManager.save(derivedContext)
        }
    }

    /// Invalidates the local cache for the notification with the specified ID.
    ///
    func invalidateCacheForNotification(with noteID: String) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)
        let predicate = NSPredicate(format: "(notificationId == %@)", noteID)

        derivedContext.perform {
            guard let notification = derivedContext.firstObject(ofType: Notification.self, matching: predicate) else {
                return
            }

            notification.notificationHash = nil

            self.contextManager.save(derivedContext)
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
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)

        derivedContext.perform {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "(notificationId IN %@)", remoteIds)
            var localHashes = [String: String]()

            for note in derivedContext.allObjects(ofType: Notification.self, matching: predicate) {
                localHashes[note.notificationId] = note.notificationHash ?? ""
            }

            let filtered = remoteHashes.filter { remote in
                let localHash = localHashes[remote.notificationId]
                return localHash == nil || localHash != remote.notificationHash
            }

            derivedContext.reset()

            let outdatedIds = filtered.map { $0.notificationId }

            DispatchQueue.main.async {
                completion(outdatedIds)
            }
        }
    }


    /// Given a collection of remoteNotes, this method will insert missing local ones, and update the ones
    /// that can be found.
    ///
    /// - Parameters:
    ///     - remoteNotes: Collection of Remote Notes
    ///     - completion: Callback to be executed on completion
    ///
    func updateLocalNotes(with remoteNotes: [RemoteNotification], completion: (() -> Void)? = nil) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)

        derivedContext.perform {
            for remoteNote in remoteNotes {
                let predicate = NSPredicate(format: "(notificationId == %@)", remoteNote.notificationId)
                let localNote = derivedContext.firstObject(ofType: Notification.self, matching: predicate) ?? derivedContext.insertNewObject(ofType: Notification.self)

                localNote.update(with: remoteNote)
            }

            self.contextManager.save(derivedContext) {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }


    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteHashes: Collection of remoteNotifications.
    ///
    func deleteLocalMissingNotes(from remoteHashes: [RemoteNotification], completion: @escaping (() -> Void)) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)

        derivedContext.perform {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "NOT (notificationId IN %@)", remoteIds)

            for orphan in derivedContext.allObjects(ofType: Notification.self, matching: predicate) {
                derivedContext.deleteObject(orphan)
            }

            self.contextManager.save(derivedContext) {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
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
        let note = mainContext.loadObject(ofType: Notification.self, with: noteObjectID)
        note?.read = status
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



// MARK: - Thread Safety Helpers
//
extension NotificationSyncMediator {
    /// Returns the current Shared Derived Context, if any. Otherwise, proceeds to create a new
    /// derived context, given a specified ContextManager.
    ///
    static func sharedDerivedContext(with manager: ContextManager) -> NSManagedObjectContext {
        lock.lock()
        if privateContext == nil {
            privateContext = manager.newDerivedContext()
        }
        lock.unlock()

        return privateContext
    }

    /// Nukes the private Shared Derived Context instance. For unit testing purposes.
    ///
    static func resetSharedDerivedContext() {
        privateContext = nil
    }
}
