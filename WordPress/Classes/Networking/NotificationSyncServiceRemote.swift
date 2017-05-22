import Foundation



// MARK: - NotificationSyncServiceRemote
//
class NotificationSyncServiceRemote: ServiceRemoteWordPressComREST {
    // MARK: - Constants
    //
    fileprivate let defaultPageSize = 100


    // MARK: - Errors
    //
    enum SyncError: Error {
        case failed
    }



    /// Retrieves latest Notifications (OR collection of Notifications, whenever noteIds is present)
    ///
    /// - Parameters:
    ///     - pageSize: Number of hashes to retrieve.
    ///     - noteIds: Identifiers of notifications to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    ///
    func loadNotes(withPageSize pageSize: Int? = nil, noteIds: [String]? = nil, completion: @escaping ((Error?, [RemoteNotification]?) -> Void)) {
        let fields = "id,note_hash,type,unread,body,subject,timestamp,meta"

        loadNotes(withNoteIds: noteIds, fields: fields, pageSize: pageSize) { error, notes in
            completion(error, notes)
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
    func loadHashes(withPageSize pageSize: Int? = nil, noteIds: [String]? = nil, completion: @escaping ((Error?, [RemoteNotification]?) -> Void)) {
        let fields = "id,note_hash"

        loadNotes(withNoteIds: noteIds, fields: fields, pageSize: pageSize) { error, notes in
            completion(error, notes)
        }
    }


    /// Updates a Notification's Read Status as specified.
    ///
    /// - Parameters:
    ///     - notificationID: The NotificationID to Mark as Read.
    ///     - read: The new Read Status to set.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateReadStatus(_ notificationID: String, read: Bool, completion: @escaping ((Error?) -> Void)) {
        let path = "notifications/read"
        let requestUrl = self.path(forEndpoint: path, with: .version_1_1)

        // Note: Isn't the API wonderful?
        let value = read ? 9999 : -9999

        let parameters = [
            "counts": ["\(notificationID)": value]
        ]

        wordPressComRestApi.POST(requestUrl!, parameters: parameters as [String : AnyObject]?, success: { (response, _)  in
            let error = self.errorFromResponse(response)
            completion(error)

        }, failure: { (error, _) in
            completion(error)
        })
    }


    /// Updates the Last Seen Notification's Timestamp.
    ///
    /// - Parameters:
    ///     - lastSeen: Timestamp of the last seen notification.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateLastSeen(_ timestamp: String, completion: @escaping ((Error?) -> Void)) {
        let path = "notifications/seen"
        let requestUrl = self.path(forEndpoint: path, with: .version_1_1)

        let parameters = [
            "time": timestamp
        ]

        wordPressComRestApi.POST(requestUrl!, parameters: parameters as [String : AnyObject]?, success: { (response, _)  in
            let error = self.errorFromResponse(response)
            completion(error)

        }, failure: { (error, _) in
            completion(error)
        })
    }
}



// MARK: - Private Methods
//
private extension NotificationSyncServiceRemote {
    /// Attempts to parse the `success` field of a given response. When it's missing, or it's false,
    /// this method will return SyncError.failed.
    ///
    /// - Parameter response: JSON entity , as retrieved from the backend.
    ///
    /// - Returns: SyncError.failed whenever the success field is either missing, or set to false.
    ///
    func errorFromResponse(_ response: AnyObject) -> Error? {
        let document = response as? [String: AnyObject]
        let success = document?["success"] as? Bool
        guard success != true else {
            return nil
        }

        return SyncError.failed
    }


    /// Retrieves the Notification for the specified pageSize (OR collection of NoteID's, when present).
    /// Note that only the specified fields will be retrieved.
    ///
    /// - Parameters:
    ///     - noteIds: Identifier for the notifications that should be loaded.
    ///     - fields: List of comma separated fields, to be loaded.
    ///     - pageSize: Number of notifications to load.
    ///     - completion: Callback to be executed on completion.
    ///
    func loadNotes(withNoteIds noteIds: [String]? = nil, fields: String? = nil, pageSize: Int?, completion: @escaping ((Error?, [RemoteNotification]?) -> Void)) {
        let path = "notifications/"
        let requestUrl = self.path(forEndpoint: path, with: .version_1_1)

        var parameters: [String: AnyObject] = [
            "number": pageSize as AnyObject? ?? defaultPageSize as AnyObject
        ]

        if let notificationIds = noteIds {
            parameters["ids"] = (notificationIds as NSArray).componentsJoined(by: ",") as AnyObject?
        }

        if let fields = fields {
            parameters["fields"] = fields as AnyObject?
        }

        wordPressComRestApi.GET(requestUrl!, parameters: parameters, success: { response, _  in
            let document = response as? [String: AnyObject]
            let notes = document?["notes"] as? [[String: AnyObject]]
            let parsed = notes?.flatMap { RemoteNotification(document: $0) }

            if let parsed = parsed {
                completion(nil, parsed)
            } else {
                completion(SyncError.failed, nil)
            }

        }, failure: { error, _ in
            completion(error, nil)
        })
    }
}
