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

    /// Returns the body of the notification.
    ///
    /// - Returns: the formatted body of the notification if it exists; `nil` otherwise
    func formatAttributedBody() -> NSAttributedString? {
        guard
            let body = notification.body,
            let bodyBlocks = body as? [[String: AnyObject]],
            !bodyBlocks.isEmpty
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
            let commentText = comment.text,
            !commentText.isEmpty
        else
        {
            return nil
        }

        let trimmedText = replaceCommonWhitespaceIssues(in: commentText)
        let styles = RemoteNotificationStyles()
        let attributedText = NSMutableAttributedString(string: trimmedText, attributes: styles.attributes)

        var lengthShift = 0
        for range in comment.ranges {
            lengthShift += range.apply(styles, to: attributedText, withShift: lengthShift)
        }

        return attributedText.trimNewlines()
    }

    /// Returns the subject of the notification.
    ///
    /// - Returns: the formatted subject of the notification if it exists; `nil` otherwise
    func formatAttributedSubject() -> NSAttributedString? {
        guard
            let subject = notification.subject,
            let subjectBlocks = subject as? [[String: AnyObject]],
            !subjectBlocks.isEmpty
        else
        {
            return nil
        }

        let blocks = NotificationContentFactory.content(
            from: subjectBlocks,
            actionsParser: parser,
            parent: notification)

        let subjectContentGroup = FormattableContentGroup(blocks: blocks, kind: .subject)
        let subjectContentBlocks = subjectContentGroup.blocks

        guard
            !subjectContentBlocks.isEmpty,
            let subjectContentBlock = subjectContentBlocks.first,
            let subjectText = subjectContentBlock.text
        else
        {
            return nil
        }

        let trimmedText = replaceCommonWhitespaceIssues(in: subjectText)
        let styles = RemoteNotificationStyles()
        let attributedText = NSMutableAttributedString(string: trimmedText, attributes: styles.attributes)

        var lengthShift = 0
        for range in subjectContentBlock.ranges {
            lengthShift += range.apply(styles, to: attributedText, withShift: lengthShift)
        }

        return attributedText.trimNewlines()
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
            let commentText = comment.text,
            !commentText.isEmpty
        else
        {
            return nil
        }

        return commentText
    }
}

// MARK: FormattableContentFormatter adaptation; importing it directly is problematic

extension RichNotificationContentFormatter {
    /// Replaces some common extra whitespace with hairline spaces so that comments display better
    ///
    /// - Parameter baseString: string of the comment body before attributes are added
    /// - Returns: string of same length
    /// - Note: the length must be maintained or the formatting will break
    private func replaceCommonWhitespaceIssues(in baseString: String) -> String {
        var newString: String
        // \u{200A} = hairline space (very skinny space).
        // we use these so that the ranges are still in the right position, but the extra space basically disappears
        newString = baseString.replacingOccurrences(of: "\t ", with: "\u{200A}\u{200A}") // tabs before a space
        newString = newString.replacingOccurrences(of: " \t", with: " \u{200A}") // tabs after a space
        newString = newString.replacingOccurrences(of: "\t@", with: "\u{200A}@") // tabs before @mentions
        newString = newString.replacingOccurrences(of: "\t.", with: "\u{200A}.") // tabs before a space
        newString = newString.replacingOccurrences(of: "\t,", with: "\u{200A},") // tabs cefore a comman
        newString = newString.replacingOccurrences(of: "\n\t\n\t", with: "\u{200A}\u{200A}\n\t") // extra newline-with-tab before a newline-with-tab

        // if the length of the string changes the range-based formatting will break
        guard newString.count == baseString.count else {
            return baseString
        }

        return newString
    }
}
