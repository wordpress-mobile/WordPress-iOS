import Foundation

enum Strings {
    static let title = NSLocalizedString(
        "commentsList.screen.title",
        value: "Comments",
        comment: "Title for the comments list screen"
    )

    static let tabAll = NSLocalizedString(
        "commentsList.tab.all",
        value: "All",
        comment: "Tab title showing pending and approved comments"
    )

    static let tabPending = NSLocalizedString(
        "commentsList.tab.pending",
        value: "Pending",
        comment: "Tab title showing comments awaiting moderation"
    )

    static let tabApproved = NSLocalizedString(
        "commentsList.tab.approved",
        value: "Approved",
        comment: "Tab title showing approved comments"
    )

    static let tabSpam = NSLocalizedString(
        "commentsList.tab.spam",
        value: "Spam",
        comment: "Tab title showing comments marked as spam"
    )

    static let tabTrash = NSLocalizedString(
        "commentsList.tab.trash",
        value: "Trash",
        comment: "Tab title showing trashed comments"
    )

    static let emptyAll = NSLocalizedString(
        "commentsList.empty.all",
        value: "No comments yet",
        comment: "Empty state message on the All tab"
    )

    static let emptyPending = NSLocalizedString(
        "commentsList.empty.pending",
        value: "No pending comments",
        comment: "Empty state message on the Pending tab"
    )

    static let emptyApproved = NSLocalizedString(
        "commentsList.empty.approved",
        value: "No approved comments",
        comment: "Empty state message on the Approved tab"
    )

    static let emptySpam = NSLocalizedString(
        "commentsList.empty.spam",
        value: "No spam comments",
        comment: "Empty state message on the Spam tab"
    )

    static let emptyTrash = NSLocalizedString(
        "commentsList.empty.trash",
        value: "No trashed comments",
        comment: "Empty state message on the Trash tab"
    )

    static let errorTitle = NSLocalizedString(
        "commentsList.error.title",
        value: "Couldn't load comments",
        comment: "Error state title when the comments list fails to load"
    )

    static let errorRetry = NSLocalizedString(
        "commentsList.error.retry",
        value: "Try again",
        comment: "Button label to retry loading comments after an error"
    )

    static let anonymousAuthor = NSLocalizedString(
        "commentsList.row.anonymousAuthor",
        value: "Anonymous",
        comment: "Author name shown when a comment has no author name"
    )

    static let authorOnPost = NSLocalizedString(
        "commentsList.row.authorOnPost",
        value: "%1$@ on %2$@",
        comment: "Comment row headline. %1$@ is the comment author, %2$@ is the post title."
    )

    static let pendingAccessibilityValue = NSLocalizedString(
        "commentsList.row.pendingAccessibilityValue",
        value: "Pending",
        comment: "Accessibility value announced for a comment row that is awaiting moderation"
    )

    static let moderationFailed = NSLocalizedString(
        "commentDetail.moderation.failed",
        value: "That action couldn't be completed. Please try again.",
        comment:
            "Notice shown when a moderation action failed; the comment keeps its pre-action status and the user can retry"
    )

    static let statusApproved = NSLocalizedString(
        "commentDetail.status.approved",
        value: "Approved",
        comment: "Status pill label on the comment detail screen for an approved comment"
    )

    static let statusPending = NSLocalizedString(
        "commentDetail.status.pending",
        value: "Pending",
        comment: "Status pill label on the comment detail screen for a comment awaiting moderation"
    )

    static let statusSpam = NSLocalizedString(
        "commentDetail.status.spam",
        value: "Spam",
        comment: "Status pill label on the comment detail screen for a comment marked as spam"
    )

    static let statusTrash = NSLocalizedString(
        "commentDetail.status.trash",
        value: "Trash",
        comment: "Status pill label on the comment detail screen for a trashed comment"
    )

    static let authorHeaderOnPost = NSLocalizedString(
        "commentDetail.header.onPost",
        value: "on %@",
        comment: "Secondary line under the comment author. %@ is the post title the comment was left on."
    )

    static let infoDateLabel = NSLocalizedString(
        "commentDetail.info.date",
        value: "Date",
        comment: "Label for the full comment date row in the author info sheet"
    )

    static let infoWebsiteLabel = NSLocalizedString(
        "commentDetail.info.website",
        value: "Website",
        comment: "Label for the author website row in the author info sheet"
    )

    static let infoEmailLabel = NSLocalizedString(
        "commentDetail.info.email",
        value: "Email",
        comment: "Label for the author email row in the author info sheet"
    )

    static let infoIPLabel = NSLocalizedString(
        "commentDetail.info.ipAddress",
        value: "IP address",
        comment: "Label for the author IP address row in the author info sheet"
    )

    static let inReplyToFormat = NSLocalizedString(
        "commentDetail.parent.inReplyTo",
        value: "In reply to %@",
        comment: "Prefix of the parent-comment strip. %@ is the parent comment's author name."
    )

    static let approve = NSLocalizedString(
        "commentDetail.action.approve",
        value: "Approve",
        comment: "Moderation toolbar button that approves a pending comment"
    )

    static let spam = NSLocalizedString(
        "commentDetail.action.spam",
        value: "Spam",
        comment: "Moderation toolbar button that marks a comment as spam"
    )

    static let trash = NSLocalizedString(
        "commentDetail.action.trash",
        value: "Trash",
        comment: "Moderation toolbar button that moves a comment to the trash"
    )

    static let moveToPending = NSLocalizedString(
        "commentDetail.action.moveToPending",
        value: "Move to Pending",
        comment: "Moderation menu item that returns an approved comment to the pending state"
    )

    static let restore = NSLocalizedString(
        "commentDetail.action.restore",
        value: "Restore",
        comment: "Moderation toolbar button that restores a comment from spam or trash"
    )

    static let deletePermanently = NSLocalizedString(
        "commentDetail.action.deletePermanently",
        value: "Delete Permanently",
        comment: "Moderation toolbar button that permanently deletes a comment"
    )

    static let detailMoreActions = NSLocalizedString(
        "commentDetail.action.moreActions",
        value: "More",
        comment: "Accessibility label for the overflow menu button on the comment detail screen"
    )

    static let trashConfirmButton = NSLocalizedString(
        "commentDetail.confirm.trashButton",
        value: "Move to Trash",
        comment: "Confirmation button that trashes a comment"
    )

    static let trashConfirmGenericTitle = NSLocalizedString(
        "commentDetail.confirm.trashGeneric",
        value: "Move this comment to the trash?",
        comment: "Confirmation title shown before trashing a comment whose reply count is unknown"
    )

    static let trashHasReplies = NSLocalizedString(
        "commentDetail.confirm.trashHasReplies",
        value: "This comment has replies. Trash it anyway?",
        comment:
            "Confirmation title before trashing a comment that has replies. Warns the moderator that the comment has replies. Trashing the comment does not trash its replies."
    )

    static let deleteConfirmTitle = NSLocalizedString(
        "commentDetail.confirm.deleteTitle",
        value: "Delete this comment permanently?",
        comment: "Confirmation title shown before permanently deleting a comment"
    )

    static let deleteConfirmMessage = NSLocalizedString(
        "commentDetail.confirm.deleteMessage",
        value: "This can't be undone.",
        comment: "Confirmation message shown before permanently deleting a comment"
    )

    static let detailErrorTitle = NSLocalizedString(
        "commentDetail.error.title",
        value: "Couldn't load this comment",
        comment: "Error state title when the comment detail fails to load"
    )
}
