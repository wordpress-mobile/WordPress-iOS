import Foundation


// MARK: - NotificationSyncServiceRemote
//
class NotificationSyncServiceRemote: ServiceRemoteWordPressComREST
{
    /// Updates a Notification's Status as specified.
    ///
    /// - Parameters:
    ///     - notificationID: The NotificationID to Mark as Read.
    ///     - read: The new Read Status to set.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateStatus(notificationID: String, read: Bool, completion: (Bool -> Void)?) {
        let path = "notifications/read"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)

        let parameters = [
            "counts": [notificationID, read]
        ]

        wordPressComRestApi.POST(requestUrl, parameters: parameters, success: { (_, _)  in
            completion?(true)
        }, failure:{ (error, _) in
            DDLogSwift.logError("Error while Marking Notification as Read: \(error)")
            completion?(false)
        })
    }

    /// Updates the Last Seen Notification's Timestamp.
    ///
    /// - Parameters:
    ///     - lastSeen: Timestamp of the last seen notification.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    func updateLastSeen(lastSeen: String, completion: (Bool -> Void)?) {
        let path = "notifications/seen"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)
        let parameters = ["time": lastSeen]

        wordPressComRestApi.POST(requestUrl, parameters: parameters, success: { (_, _)  in
            completion?(true)
        }, failure:{ (error, _) in
            DDLogSwift.logError("Error while Updating Last Seen Timestamp: \(error)")
            completion?(false)
        })
    }
}
