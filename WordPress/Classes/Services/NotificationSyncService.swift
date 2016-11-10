import Foundation


// MARK: - Notifications
//
let NotificationSyncServiceDidUpdateNotifications = "NotificationSyncServiceDidUpdateNotifications"


// MARK: - NotificationSyncService
//
class NotificationSyncService
{
    /// Returns the Main Managed Context
    ///
    private let contextManager: ContextManager

    /// Sync Service Remote
    ///
    private let remote: NotificationSyncServiceRemote

    /// Maximum number of Notes to Sync
    ///
    private let maximumNotes = 100

    /// Returns the main CoredAta Context
    ///
    private var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }



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
    func sync(completion: ((ErrorType?, Bool) -> Void)? = nil) {
        assert(NSThread.isMainThread())

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
    func syncNote(with noteId: String, completion: ((ErrorType?, Notification?) -> Void)) {
        assert(NSThread.isMainThread())

        remote.loadNotes(noteIds: [noteId]) { error, remoteNotes in
            guard let remoteNotes = remoteNotes else {
                completion(error, nil)
                return
            }

            self.updateLocalNotes(with: remoteNotes) {
                let helper = CoreDataHelper<Notification>(context: self.mainContext)
                let predicate = NSPredicate(format: "(notificationId == %@)", noteId)
                let note = helper.firstObject(matchingPredicate: predicate)

                completion(nil, note)
            }
        }
    }


    /// Marks a Notification as Read. On error, proceeds to revert the change.
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - notification: The notification that was just read.
    ///     - completion: Callback to be executed on completion.
    ///
    func markAsRead(notification: Notification, completion: (ErrorType?-> Void)? = nil) {
        assert(NSThread.isMainThread())

        let original = notification.read

        remote.updateReadStatus(notification.notificationId, read: true) { error in
            if let error = error {
                DDLogSwift.logError("Error marking note as read: \(error)")
                self.updateReadStatus(original, forNoteWithObjectID: notification.objectID)
            }

            completion?(error)
        }

        updateReadStatus(true, forNoteWithObjectID: notification.objectID)
    }


    /// Updates the Backend's Last Seen Timestamp. Used to calculate the Badge Count!
    ///
    /// - Note: This method should only be used on the main thread.
    ///
    /// - Parameters:
    ///     - timestamp: Timestamp of the last seen notification.
    ///     - completion: Callback to be executed on completion.
    ///
    func updateLastSeen(timestamp: String, completion: (ErrorType? -> Void)? = nil) {
        assert(NSThread.isMainThread())

        remote.updateLastSeen(timestamp) { error in
            if let error = error {
                DDLogSwift.logError("Error while Updating Last Seen Timestamp: \(error)")
            }

            completion?(error)
        }
    }
}


// MARK: - Private Helpers
//
private extension NotificationSyncService
{
    /// Given a collection of RemoteNotification Hashes, this method will determine the NotificationID's
    /// that are either missing in our database, or have been remotely updated.
    ///
    /// - Parameters:
    ///     - remoteHashes: Collection of Notification Hashes
    ///     - completion: Callback to be executed on completion
    ///
    func determineUpdatedNotes(with remoteHashes: [RemoteNotification], completion: ([String] -> Void)) {
        let derivedContext = contextManager.newDerivedContext()
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.performBlock {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "(notificationId IN %@)", remoteIds)
            var localHashes = [String: String]()

            for note in helper.allObjects(matchingPredicate: predicate) {
                localHashes[note.notificationId] = note.notificationHash ?? ""
            }

            let filtered = remoteHashes.filter { remote in
                let localHash = localHashes[remote.notificationId]
                return localHash == nil || localHash != remote.notificationHash
            }

            derivedContext.reset()

            let outdatedIds = filtered.map { $0.notificationId }

            dispatch_async(dispatch_get_main_queue()) {
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
    func updateLocalNotes(with remoteNotes: [RemoteNotification], completion: (Void -> Void)? = nil) {
        let derivedContext = contextManager.newDerivedContext()
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.performBlock {
            for remoteNote in remoteNotes {
                let predicate = NSPredicate(format: "(notificationId == %@)", remoteNote.notificationId)
                let localNote = helper.firstObject(matchingPredicate: predicate) ?? helper.insertNewObject()

                localNote.update(with: remoteNote)
            }

            self.contextManager.saveDerivedContext(derivedContext) {
                dispatch_async(dispatch_get_main_queue()) {
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
    func deleteLocalMissingNotes(from remoteHashes: [RemoteNotification], completion: (Void -> Void)) {
        let derivedContext = contextManager.newDerivedContext()
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.performBlock {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "NOT (notificationId IN %@)", remoteIds)

            for orphan in helper.allObjects(matchingPredicate: predicate) {
                helper.deleteObject(orphan)
            }

            self.contextManager.saveDerivedContext(derivedContext) {
                dispatch_async(dispatch_get_main_queue()) {
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
    func updateReadStatus(status: Bool, forNoteWithObjectID noteObjectID: NSManagedObjectID) {
        let helper = CoreDataHelper<Notification>(context: mainContext)
        let note = helper.loadObject(withObjectID: noteObjectID)
        note?.read = status
        contextManager.saveContextAndWait(mainContext)
    }


    /// Posts a `NotificationSyncServiceDidUpdateNotifications` Notification, so that (potential listeners)
    /// may react upon new content.
    ///
    func notifyNotificationsWereUpdated() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName(NotificationSyncServiceDidUpdateNotifications, object: nil)
    }
}
