import WordPressKit

/// Known kinds of Notifications
import Foundation

// MARK: - NotificationKind

/// Characterizes the known types of notification types
enum NotificationKind: String {
    case comment        = "comment"
    case commentLike    = "comment_like"
    case follow         = "follow"
    case like           = "like"
    case matcher        = "automattcher"
    case newPost        = "new_post"
    case post           = "post"
    case user           = "user"
    case login          = "push_auth"
    case unknown        = "unknown"
}

extension NotificationKind {
    /// Enumerates the Kinds that currently provide Rich Notification support
    private static var kindsWithRichNotificationSupport: Set<NotificationKind> = [
        .comment,
        .commentLike,
        .like,
        .matcher,
        .login,
    ]

    /// Enumerates the Kinds of rich notifications that include body text
    private static var kindsWithoutRichNotificationBodyText: Set<NotificationKind> = [
        .commentLike,
        .like,
        .login,
    ]

    /// Indicates whether or not a given kind of rich notification has a body support.
    ///
    /// - Parameter kind: the notification type to evaluate
    /// - Returns: `true` if the kind of rich notification includes a body; `false` otherwise
    static func omitsRichNotificationBody(_ kind: NotificationKind) -> Bool {
        return kindsWithoutRichNotificationBodyText.contains(kind)
    }

    /// Indicates whether or not a given kind has rich notification support.
    ///
    /// - Parameter kind: the notification type to evaluate
    /// - Returns: `true` if the kind supports rich notifications; `false` otherwise
    static func isSupportedByRichNotifications(_ kind: NotificationKind) -> Bool {
        return kindsWithRichNotificationSupport.contains(kind)
    }

    /// Returns a client-side notification category. The category provides a match to ensure that the Long Look
    /// can be presented.
    ///
    /// NB: These should all be set on the server, but in practice, they are not.
    ///
    var contentExtensionCategoryIdentifier: String? {
        switch self {
        case .commentLike, .like, .matcher, .login:
            return rawValue
        default:
            return nil
        }
    }
}

// MARK: - Notifiable

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

// MARK: - RemoteNotification

/// RemoteNotification is located in WordPressKit
extension RemoteNotification: Notifiable {
    var notificationIdentifier: String {
        return notificationId
    }
}
