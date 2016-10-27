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


    /// Syncs the latest *maximumNotes*: Deletes old entities, and upserts new ones!
    ///
    func sync() {
        // Load latest 100 Notification Hashes. ++performance++
        remote.loadLastestHashes(withPageSize: maximumNotes) { hashes in
            guard let hashes = hashes else {
                return
            }

            // Determine which notifications must be downloaded
            self.process(remoteNotificationHashes: hashes) { noteIds in

                // Load Full Notification Documents
                self.remote.loadNotes(noteIds: noteIds) { (notifications) in
                    guard let notifications = notifications else {
                        return
                    }

                    // Merge!
                    self.merge(remoteNotifications: notifications)
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
    func process(remoteNotificationHashes hashes: [RemoteNotification], completion: ([String] -> Void)) {
        let noteIds = hashes.map { $0.notificationId }
        completion(noteIds)
    }


    ///
    ///
    func merge(remoteNotifications notes: [RemoteNotification]) {
        // Update Newest
        // Delete Removed
    }


    ///
    ///
    func update(notification local: Notification, with remote: RemoteNotification) {
        local.notificationHash = remote.notificationHash
        local.read = remote.read
        local.icon = remote.icon
        local.noticon = remote.noticon
        local.timestamp = remote.timestamp
        local.type = remote.type
        local.url = remote.url
        local.title = remote.title
        local.subject = remote.subject
        local.header = remote.header
        local.body = remote.body
        local.meta = remote.meta
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
