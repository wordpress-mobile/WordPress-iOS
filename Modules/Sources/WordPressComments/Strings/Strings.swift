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
}
