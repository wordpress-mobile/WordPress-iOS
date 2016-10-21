import Foundation


// MARK: NotificationSyncService
//
class NotificationSyncService
{
    ///
    ///
    private var remote: NotificationSyncServiceRemote!

    ///
    ///
    init?() {
        guard let dotcomAPI = dotcomAPI else {
            return nil
        }

        remote = NotificationSyncServiceRemote(wordPressComRestApi: dotcomAPI)
    }



    /// GET /rest/v1.1/notifications/?http_envelope=1&fields=id%2Ctype%2Cunread%2Cbody%2Csubject%2Ctimestamp%2Cmeta%2Cnote_hash&number=10 HTTP/1.1
    ///
    func sync() {

    }

    /// Marks a Notification as Read. On error, proceeds to revert the change.
    ///
    /// - Paramter notification: The notification that was just read.
    ///
    func markAsRead(notification: Notification) {
        assert(NSThread.isMainThread())

        let original = notification.read

        remote.updateStatus(notification.notificationId, read: true) { success in
            if success {
                return
            }

            self.updateStatus(original, forNoteWithObjectID: notification.objectID)
        }

        updateStatus(false, forNoteWithObjectID: notification.objectID)
    }

    /// Updates the Backend's Last Seen Timestamp. Used to calculate the Badge Count!
    ///
    /// - Parameter timestamp: Timestamp of the last seen notification.
    ///
    func updateLastSeen(timestamp: String) {
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
    func updateStatus(status: Bool, forNoteWithObjectID noteObjectID: NSManagedObjectID) {
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
