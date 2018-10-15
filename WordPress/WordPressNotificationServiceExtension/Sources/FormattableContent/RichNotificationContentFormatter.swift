import Foundation

import WordPressKit

// MARK: - RichNotificationContentFormatter

/// Responsible for transforming a `RemoteNotification` into both plain & attributed text representations.
/// The class abstracts access to `FormattableContent`.
///
class RichNotificationContentFormatter {

    /// The remote notification to format
    private let notification: RemoteNotification

    /// The parser used to render blocks in the notification.
    private let parser: FormattableContentActionParser

    /// The plain-text representation of the notification body, suitable for Short Look presentation
    var body: String?

    /// The attributed-text representation of the notification body, suitable for Long Look presentation
    var attributedBody: NSAttributedString?

    /// The attributed-text representation of the notification subject, suitable for Long Look presentation
    var attributedSubject: NSAttributedString?

    /// Creates a notification content formatter.
    ///
    /// - Parameters:
    ///   - notification: the RemoteNotification to format
    ///   - parser: the `FormattableContentActionParser` specified; defaults to `RemoteNotificationActionParser`
    init(notification: RemoteNotification, parser: FormattableContentActionParser = RemoteNotificationActionParser()) {
        self.notification = notification
        self.parser = parser

        formatAttributedSubject()
        formatBody()
    }
}

// MARK: - Private behavior

private extension RichNotificationContentFormatter {
    /// Attempts to format both a plain-text & attributed-text representation of the notification content.
    func formatBody() {
        guard NotificationKind.omitsRichNotificationBody(notification.kind) == false,
            let body = notification.body,
            let bodyBlocks = body as? [[String: AnyObject]],
            bodyBlocks.isEmpty == false else {

            return
        }

        let blocks = NotificationContentFactory.content(from: bodyBlocks, actionsParser: parser, parent: notification)

        let formattableContent: FormattableContent?
        if let commentContent: FormattableCommentContent = FormattableContentGroup.blockOfKind(.comment, from: blocks) {
            formattableContent = commentContent
        } else {
            let bodyContentGroup = FormattableContentGroup(blocks: blocks, kind: .text)
            let bodyContentBlocks = bodyContentGroup.blocks

            if bodyContentBlocks.isEmpty == false,
                let bodyContentBlock = bodyContentBlocks.first {

                formattableContent = bodyContentBlock
            } else {
                formattableContent = nil
            }
        }

        guard let validContent = formattableContent,
            let bodyText = validContent.text else {

            return
        }

        let trimmedText = replaceCommonWhitespaceIssues(in: bodyText)
        let styles = RemoteNotificationStyles()
        let attributedText = NSMutableAttributedString(string: trimmedText, attributes: styles.attributes)

        var lengthShift = 0
        for range in validContent.ranges {
            lengthShift += range.apply(styles, to: attributedText, withShift: lengthShift)
        }

        let formattedBody = attributedText.trimNewlines()

        self.body = formattedBody.string
        self.attributedBody = formattedBody
    }

    /// Attempts to format the attributed subject of the notification content.
    func formatAttributedSubject() {
        guard let subject = notification.subject,
            let subjectBlocks = subject as? [[String: AnyObject]],
            subjectBlocks.isEmpty == false else {

            return
        }

        let blocks = NotificationContentFactory.content(from: subjectBlocks, actionsParser: parser, parent: notification)
        let subjectContentGroup = FormattableContentGroup(blocks: blocks, kind: .subject)
        let subjectContentBlocks = subjectContentGroup.blocks

        guard subjectContentBlocks.isEmpty == false,
            let subjectContentBlock = subjectContentBlocks.first,
            let subjectText = subjectContentBlock.text else {

            return
        }

        let trimmedText = replaceCommonWhitespaceIssues(in: subjectText)
        let styles = RemoteNotificationStyles()
        let attributedText = NSMutableAttributedString(string: trimmedText, attributes: styles.attributes)

        var lengthShift = 0
        for range in subjectContentBlock.ranges {
            lengthShift += range.apply(styles, to: attributedText, withShift: lengthShift)
        }

        self.attributedSubject = attributedText.trimNewlines()
    }

    /// Replaces some common extra whitespace with hairline spaces so that comments display better
    ///
    /// - Parameter baseString: string of the comment body before attributes are added
    /// - Returns: string of same length
    /// - Note: the length must be maintained or the formatting will break
    func replaceCommonWhitespaceIssues(in baseString: String) -> String {
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
