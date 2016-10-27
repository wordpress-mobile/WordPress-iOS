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
        remote.loadHashes(withPageSize: maximumNotes) { hashes in
            guard let hashes = hashes else {
                return
            }

            self.determineUpdatedNotes(withRemoteHashes: hashes) { noteIds in

                self.remote.loadNotes(noteIds: noteIds) { remoteNotes in
                    guard let remoteNotes = remoteNotes else {
                        return
                    }

                    self.updateLocalNotes(withRemoteNotes: remoteNotes)
                    self.deleteLocalMissingNotes(fromRemoteHashes: hashes)
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
    func determineUpdatedNotes(withRemoteHashes hashes: [RemoteNotification], completion: ([String] -> Void)) {
        let noteIds = hashes.map { $0.notificationId }
        completion(noteIds)
    }


    ///
    ///
    func updateLocalNotes(withRemoteNotes notes: [RemoteNotification]) {
        // Update Newest
        // Insert Missing
    }


    ///
    ///
    func deleteLocalMissingNotes(fromRemoteHashes hashes: [RemoteNotification]) {
        // Delete Removed
        let remoteIds = hashes.map { $0.notificationId }
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
