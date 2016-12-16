import Foundation


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
class NotificationSyncMediator
{
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
        let service = AccountService(managedObjectContext: manager?.mainContext)

        guard let dotcomAPI = service?.defaultWordPressComAccount()?.wordPressComRestApi else {
            return nil
        }

        self.init(manager: manager!, dotcomAPI: dotcomAPI)
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
    func syncNote(with noteId: String, completion: @escaping ((Error?, Notification?) -> Void)) {
        assert(Thread.isMainThread)

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
    func markAsRead(_ notification: Notification, completion: ((Error?)-> Void)? = nil) {
        assert(Thread.isMainThread)

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
    func updateLastSeen(_ timestamp: String, completion: ((Error?) -> Void)? = nil) {
        assert(Thread.isMainThread)

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
private extension NotificationSyncMediator
{
    /// Given a collection of RemoteNotification Hashes, this method will determine the NotificationID's
    /// that are either missing in our database, or have been remotely updated.
    ///
    /// - Parameters:
    ///     - remoteHashes: Collection of Notification Hashes
    ///     - completion: Callback to be executed on completion
    ///
    func determineUpdatedNotes(with remoteHashes: [RemoteNotification], completion: @escaping (([String]) -> Void)) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.perform {
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
    func updateLocalNotes(with remoteNotes: [RemoteNotification], completion: ((Void) -> Void)? = nil) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.perform {
            for remoteNote in remoteNotes {
                let predicate = NSPredicate(format: "(notificationId == %@)", remoteNote.notificationId)
                let localNote = helper.firstObject(matchingPredicate: predicate) ?? helper.insertNewObject()

                localNote.update(with: remoteNote)
            }

            self.contextManager.saveDerivedContext(derivedContext) {
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
    func deleteLocalMissingNotes(from remoteHashes: [RemoteNotification], completion: @escaping ((Void) -> Void)) {
        let derivedContext = type(of: self).sharedDerivedContext(with: contextManager)
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.perform {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "NOT (notificationId IN %@)", remoteIds)

            for orphan in helper.allObjects(matchingPredicate: predicate) {
                helper.deleteObject(orphan)
            }

            self.contextManager.saveDerivedContext(derivedContext) {
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
        let helper = CoreDataHelper<Notification>(context: mainContext)
        let note = helper.loadObject(withObjectID: noteObjectID)
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
extension NotificationSyncMediator
{
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
