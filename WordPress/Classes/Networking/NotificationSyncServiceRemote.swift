import Foundation



// MARK: - NotificationSyncServiceRemote
//
class NotificationSyncServiceRemote: ServiceRemoteWordPressComREST
{
    // MARK: - Constants
    private let defaultPageSize = 100


    /// Retrieves latest Notifications (OR collection of Notifications, whenever noteIds is present)
    ///
    /// - Parameters:
    ///     - pageSize: Number of hashes to retrieve.
    ///     - noteIds: Identifiers of notifications to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    ///
    func loadNotes(withPageSize pageSize: Int? = nil, noteIds: [String]? = nil, completion: ([RemoteNotification]? -> Void)) {
        let fields = "id,note_hash,type,unread,body,subject,timestamp,meta"

        loadNotes(withNoteIds: noteIds, fields: fields, pageSize: pageSize) { notes in
            completion(notes)
        }
    }


    /// Retrieves the Notification Hashes for the specified pageSize (OR collection of NoteID's, when present)
    ///
    /// - Parameters:
    ///     - pageSize: Number of hashes to retrieve.
    ///     - noteIds: Identifiers of notifications to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    /// - Notes: The RemoteNotification Entity will only have it's ID + Hash populated
    ///
    func loadHashes(withPageSize pageSize: Int? = nil, noteIds: [String]? = nil, completion: ([RemoteNotification]? -> Void)) {
        let fields = "id,note_hash"

        loadNotes(withNoteIds: noteIds, fields: fields, pageSize: pageSize) { notes in
            completion(notes)
        }
    }


    /// Updates a Notification's Read Status as specified.
    ///
    /// - Parameters:
    ///     - notificationID: The NotificationID to Mark as Read.
    ///     - read: The new Read Status to set.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateReadStatus(notificationID: String, read: Bool, completion: (Bool -> Void)) {
        let path = "notifications/read"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)

        let parameters = [
            "counts": [notificationID, read]
        ]

        wordPressComRestApi.POST(requestUrl, parameters: parameters, success: { (_, _)  in
            completion(true)
        }, failure:{ (error, _) in
            DDLogSwift.logError("Error while Marking Notification as Read: \(error.description)")
            completion(false)
        })
    }


    /// Updates the Last Seen Notification's Timestamp.
    ///
    /// - Parameters:
    ///     - lastSeen: Timestamp of the last seen notification.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateLastSeen(timestamp: String, completion: (Bool -> Void)) {
        let path = "notifications/seen"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)

        let parameters = [
            "time": timestamp
        ]

        wordPressComRestApi.POST(requestUrl, parameters: parameters, success: { (_, _)  in
            completion(true)
        }, failure:{ (error, _) in
            DDLogSwift.logError("Error while Updating Last Seen Timestamp: \(error.description)")
            completion(false)
        })
    }
}



// MARK: -  Private Methods
//
private extension NotificationSyncServiceRemote
{
    /// Retrieves the Notification for the specified pageSize (OR collection of NoteID's, when present).
    /// Note that only the specified fields will be retrieved.
    ///
    /// - Parameters:
    ///     - noteIds: Identifier for the notifications that should be loaded.
    ///     - fields: List of comma separated fields, to be loaded.
    ///     - pageSize: Number of notifications to load.
    ///     - completion: Callback to be executed on completion.
    ///
    func loadNotes(withNoteIds noteIds: [String]? = nil, fields: String? = nil, pageSize: Int?, completion: ([RemoteNotification]? -> Void)) {
        let path = "notifications/"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)

        var parameters: [String: AnyObject] = [
            "number": pageSize ?? defaultPageSize
        ]

        if let notificationIds = noteIds {
            parameters["ids"] = (notificationIds as NSArray).componentsJoinedByString(",")
        }

        if let fields = fields {
            parameters["fields"] = fields
        }

        wordPressComRestApi.GET(requestUrl, parameters: parameters, success: { (response, _)  in
            let document = response as? [String: AnyObject]
            let notes = document?["notes"] as? [[String: AnyObject]]
            let parsed = notes?.flatMap { rawNote in
                return RemoteNotification(document: rawNote)
            }

            completion(parsed)

        }, failure:{ (error, _) in
            DDLogSwift.logError("Error while Marking Notification as Read: \(error.description)")
            completion(nil)
        })
    }
}
