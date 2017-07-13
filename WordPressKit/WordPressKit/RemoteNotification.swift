import Foundation
import WordPressShared

// MARK: - RemoteNotification
//
public struct RemoteNotification {
    /// Notification's Primary Key
    ///
    public let notificationId: String

    /// Notification's Hash
    ///
    public let notificationHash: String

    /// Indicates whether the note was already read, or not
    ///
    public let read: Bool

    /// Associated Resource's Icon, as a plain string
    ///
    public let icon: String?

    /// Noticon resource, associated with this notification
    ///
    public let noticon: String?

    /// Timestamp as a String
    ///
    public let timestamp: String?

    /// Notification Type
    ///
    public let type: String?

    /// Associated Resource's URL
    ///
    public let url: String?

    /// Plain Title ("1 Like" / Etc)
    ///
    public let title: String?

    /// Raw Subject Blocks
    ///
    public let subject: [AnyObject]?

    /// Raw Header Blocks
    ///
    public let header: [AnyObject]?

    /// Raw Body Blocks
    ///
    public let body: [AnyObject]?

    /// Raw Associated Metadata
    ///
    public let meta: [String: AnyObject]?


    /// Designed Initializer
    ///
    public init?(document: [String: AnyObject]) {
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
