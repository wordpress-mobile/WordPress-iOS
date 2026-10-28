import Foundation

enum PostEditorStrings {
    // More menu
    static let codeEditor = NSLocalizedString(
        "postEditor.moreMenu.codeEditor",
        value: "Code Editor",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let visualEditor = NSLocalizedString(
        "postEditor.moreMenu.visualEditor",
        value: "Visual Editor",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let helpAndSupport = NSLocalizedString(
        "postEditor.moreMenu.helpAndSupport",
        value: "Help & Support",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let help = NSLocalizedString(
        "postEditor.moreMenu.help",
        value: "Help",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let postSettings = NSLocalizedString(
        "postEditor.moreMenu.postSettings",
        value: "Post Settings",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let sendFeedback = NSLocalizedString(
        "postEditor.moreMenu.sendFeedback",
        value: "Send Feedback",
        comment: "Post Editor / Button in the 'More' menu"
    )
    static let saveDraft = NSLocalizedString(
        "postEditor.moreMenu.saveDraft",
        value: "Save Draft",
        comment: "Post Editor / Button in the 'More' menu"
    )

    // Close confirmation
    static let keepEditing = NSLocalizedString(
        "postEditor.closeConfirmationAlert.keepEditing",
        value: "Keep Editing",
        comment: "Button to keep the changes in an alert confirming discarding changes"
    )
    static let discardChanges = NSLocalizedString(
        "postEditor.closeConfirmationAlert.discardChanges",
        value: "Discard Changes",
        comment: "Button in an alert confirming discarding changes"
    )
    static let leaveWhileUploadingTitle = NSLocalizedString(
        "postEditor.leaveWhileUploadingAlert.title",
        value: "Media is still uploading",
        comment: "Title of an alert shown when closing the editor while media is uploading"
    )
    static let leaveWhileUploadingMessage = NSLocalizedString(
        "postEditor.leaveWhileUploadingAlert.message",
        value: "If you leave now, the upload stops and the media won't be added to your post.",
        comment: "Message of an alert shown when closing the editor while media is uploading"
    )
    static let leave = NSLocalizedString(
        "postEditor.leaveWhileUploadingAlert.leave",
        value: "Leave",
        comment: "Button to close the editor in an alert shown while media is uploading"
    )

    // Primary actions
    static let publish = NSLocalizedString(
        "postEditor.publishButton.title",
        value: "Publish",
        comment: "Title for the publish button in the post editor navigation bar"
    )
    static let update = NSLocalizedString(
        "postEditor.updateButton.title",
        value: "Update",
        comment: "Title for the update button in the post editor navigation bar"
    )
}
