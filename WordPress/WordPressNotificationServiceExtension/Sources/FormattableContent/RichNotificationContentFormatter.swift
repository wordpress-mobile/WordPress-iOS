import Foundation

import WordPressKit

/// Responsible for transforming a `RemoteNotification` into both plain & attributed text representations.
/// The class abstracts access to `FormattableContent`.
///
class RichNotificationContentFormatter {

    /// The remote notification to format
    private let notification: RemoteNotification

    /// The parser used to render blocks in the notification.
    private let parser: FormattableContentActionParser

    /// Creates a notification content formatter.
    ///
    /// - Parameters:
    ///   - notification: the RemoteNotification to format
    ///   - parser: the `FormattableContentActionParser` specified; defaults to `RemoteNotificationActionParser`
    init(notification: RemoteNotification, parser: FormattableContentActionParser = RemoteNotificationActionParser()) {
        self.notification = notification
        self.parser = parser
    }

    /// Renders a plain-text representation of the notification body.
    ///
    /// - Returns: a plain-text representation of the notification body if successful; `nil` otherwise
    func formatBody() -> String? {
        guard
            let body = notification.body,
            let bodyBlocks = body as? [[String: AnyObject]]
        else
        {
            return nil
        }

        let blocks = NotificationContentFactory.content(
            from: bodyBlocks,
            actionsParser: parser,
            parent: notification)

        guard
            let comment: FormattableCommentContent = FormattableContentGroup.blockOfKind(.comment, from: blocks),
            let notificationText = comment.text,
            !notificationText.isEmpty
        else
        {
            return nil
        }

        return comment.text
    }
}
