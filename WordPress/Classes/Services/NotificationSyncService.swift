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


    ///
    ///
    func sync() {
        let start = NSDate()
        remote.loadLastestHashes(withPageSize: maximumNotes) { (notifications) in
            guard let notifications = notifications else {
                return
            }

            // Load Local Notes + Calculate Deltas
NSLog("## Load Hashes \(notifications.count) Delta \(start.timeIntervalSinceNow)")
            let noteIds = notifications.map { $0.notificationId }
            self.sync(noteIds)
        }
    }


    ///
    ///
    private func sync(noteIds: [String]) {
        let start = NSDate()
        remote.loadNotes(noteIds: noteIds) { (notifications) in
            guard let notifications = notifications else {
                return
            }
NSLog("## Load Notes \(notifications.count) Delta \(start.timeIntervalSinceNow)")
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
