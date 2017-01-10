import Foundation



// MARK: - RemoteNotification
//
struct RemoteNotification {
    /// Notification's Primary Key
    ///
    let notificationId: String

    /// Notification's Hash
    ///
    let notificationHash: String

    /// Indicates whether the note was already read, or not
    ///
    let read: Bool

    /// Associated Resource's Icon, as a plain string
    ///
    let icon: String?

    /// Noticon resource, associated with this notification
    ///
    let noticon: String?

    /// Timestamp as a String
    ///
    let timestamp: String?

    /// Notification Type
    ///
    let type: String?

    /// Associated Resource's URL
    ///
    let url: String?

    /// Plain Title ("1 Like" / Etc)
    ///
    let title: String?

    /// Raw Subject Blocks
    ///
    let subject: [AnyObject]?

    /// Raw Header Blocks
    ///
    let header: [AnyObject]?

    /// Raw Body Blocks
    ///
    let body: [AnyObject]?

    /// Raw Associated Metadata
    ///
    let meta: [String: AnyObject]?


    /// Designed Initializer
    ///
    init?(document: [String: AnyObject]) {
        guard let noteId = document.valueAsString(forKey: "id"),
            let noteHash = document.valueAsString(forKey: "note_hash") else {
            return nil
        }

        notificationId = noteId
        notificationHash = noteHash
        read = document["read"] as? Bool ?? false
        icon = document["icon"] as? String
        noticon = document["noticon"] as? String
        timestamp = document["timestamp"] as? String
        type = document["type"] as? String
        url = document["url"] as? String
        title = document["title"] as? String
        subject = document["subject"] as? [AnyObject]
        header = document["header"] as? [AnyObject]
        body = document["body"] as? [AnyObject]
        meta = document["meta"] as? [String: AnyObject]
    }
}
