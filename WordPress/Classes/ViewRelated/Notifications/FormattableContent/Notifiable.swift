import WordPressKit

/// Known kinds of Notifications
enum NotificationKind: String {
    case comment        = "comment"
    case commentLike    = "comment_like"
    case follow         = "follow"
    case like           = "like"
    case matcher        = "automattcher"
    case newPost        = "new_post"
    case post           = "post"
    case user           = "user"
    case unknown        = "unknown"
}

/// This protocol represents the traits of a local or remote notification.
protocol Notifiable {
    /// The unique identifier for the notification; `note_id` in the APNS payload, `notificationId` in Core Data
    var notificationIdentifier: String { get }

    /// The type of the notification, exposed in both Core Data & APNS payload.
    var type: String? { get }

    /// Parses the Notification.type field into a Swift Native enum. Returns .unknown on failure.
    var kind: NotificationKind { get }
}

extension Notifiable {
    var kind: NotificationKind {
        guard let type = type, let kind = NotificationKind(rawValue: type) else {
            return .unknown
        }
        return kind
    }
}

/// RemoteNotification is located in WordPressKit
extension RemoteNotification: Notifiable {
    var notificationIdentifier: String {
        return notificationId
    }
}
