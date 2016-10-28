import Foundation


// MARK: - NotificationSyncService
//
class NotificationSyncService
{
    /// Sync Service Remote
    ///
    private var remote: NotificationSyncServiceRemote!

    /// Maximum number of Notes to Sync
    ///
    private let maximumNotes = 100


    /// Designed Initializer
    ///
    init?() {
        guard let dotcomAPI = dotcomAPI else {
            return nil
        }

        remote = NotificationSyncServiceRemote(wordPressComRestApi: dotcomAPI)
    }


    /// Syncs the latest *maximumNotes*:
    ///
    /// - Latest 100 hashes are retrieved (++efficiency++)
    /// - Only those Notifications that were remotely changed (Updated / Inserted) will be retrieved
    /// - Local collection will be updated. Old notes will be purged!
    ///
    func sync() {
        remote.loadHashes(withPageSize: maximumNotes) { remoteHashes in
            guard let remoteHashes = remoteHashes else {
                return
            }

            self.determineUpdatedNotes(with: remoteHashes) { noteIds in
                guard noteIds.isEmpty == false else {
                    return
                }

                self.remote.loadNotes(noteIds: noteIds) { remoteNotes in
                    guard let remoteNotes = remoteNotes else {
                        return
                    }

                    self.updateLocalNotes(with: remoteNotes) {
                        self.deleteLocalMissingNotes(from: remoteHashes)
                    }
                }
            }
        }
    }


    /// Marks a Notification as Read. On error, proceeds to revert the change.
    ///
    /// - Paramter notification: The notification that was just read.
    ///
    func markAsRead(notification: Notification) {
        assert(NSThread.isMainThread())

        let original = notification.read

        remote.updateReadStatus(notification.notificationId, read: true) { success in
            if success {
                return
            }

            self.updateReadStatus(original, forNoteWithObjectID: notification.objectID)
        }

        updateReadStatus(true, forNoteWithObjectID: notification.objectID)
    }


    /// Updates the Backend's Last Seen Timestamp. Used to calculate the Badge Count!
    ///
    /// - Parameter timestamp: Timestamp of the last seen notification.
    ///
    func updateLastSeen(timestamp: String) {
        assert(NSThread.isMainThread())

        remote.updateLastSeen(timestamp) { success in
            if success {
                return
            }

            DDLogSwift.logError("Error while trying to update Notifications Last Seen Timestamp: \(timestamp)")
        }
    }
}


// MARK: - Private Helpers
//
private extension NotificationSyncService
{
    ///
    ///
    func determineUpdatedNotes(with remoteHashes: [RemoteNotification], completion: ([String] -> Void)) {
        let derivedContext = ContextManager.sharedInstance().newDerivedContext()
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


    ///
    ///
    func updateLocalNotes(with remoteNotes: [RemoteNotification], completion: (Void -> Void)) {
        let derivedContext = ContextManager.sharedInstance().newDerivedContext()
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.performBlock {
            for remoteNote in remoteNotes {
                let predicate = NSPredicate(format: "(notificationId == %@)", remoteNote.notificationId)
                let localNote = helper.firstObject(matchingPredicate: predicate) ?? helper.insertNewObject()

                localNote.update(with: remoteNote)
            }

            ContextManager.sharedInstance().saveDerivedContext(derivedContext) {
                completion()
            }
        }
    }


    ///
    ///
    func deleteLocalMissingNotes(from remoteHashes: [RemoteNotification]) {
        let derivedContext = ContextManager.sharedInstance().newDerivedContext()
        let helper = CoreDataHelper<Notification>(context: derivedContext)

        derivedContext.performBlock {
            let remoteIds = remoteHashes.map { $0.notificationId }
            let predicate = NSPredicate(format: "NOT (notificationId IN %@)", remoteIds)

            for orphan in helper.allObjects(matchingPredicate: predicate) {
                helper.deleteObject(orphan)
            }

            ContextManager.sharedInstance().saveDerivedContext(derivedContext)
        }
    }


    /// Updates the Read status, of a given Notification, as specified.
    ///
    /// - Parameters:
    ///     - status: New *read* value
    ///     - noteObjectID: CoreData ObjectID
    ///
    func updateReadStatus(status: Bool, forNoteWithObjectID noteObjectID: NSManagedObjectID) {
        do {
            let note = try mainContext.existingObjectWithID(noteObjectID) as? Notification
            note?.read = status
            try mainContext.save()
        } catch {
            DDLogSwift.logError("Error while Updating Notification Status: \(error)")
        }
    }
}


// MARK: - Private Properties
//
private extension NotificationSyncService
{
    /// Returns the Main Managed Context
    ///
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    /// Returns the WordPress.com REST API, if any
    ///
    var dotcomAPI: WordPressComRestApi? {
        let service = AccountService(managedObjectContext: mainContext)
        let account = service.defaultWordPressComAccount()

        guard let dotcomAPI = account?.wordPressComRestApi where dotcomAPI.hasCredentials() else {
            return nil
        }

        return dotcomAPI
    }
}
