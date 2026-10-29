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
    static let notReadyPostTitle = NSLocalizedString(
        "postEditor.notReadyAlert.postTitle",
        value: "Your post isn't ready yet",
        comment:
            "Title of an alert shown when saving or closing the editor for a post while something, like a media upload, is in progress"
    )
    static let notReadyPageTitle = NSLocalizedString(
        "postEditor.notReadyAlert.pageTitle",
        value: "Your page isn't ready yet",
        comment:
            "Title of an alert shown when saving or closing the editor for a page while something, like a media upload, is in progress"
    )
    static let leavePostWhileNotReadyMessage = NSLocalizedString(
        "postEditor.notReadyAlert.leavePostMessage",
        value:
            "If you leave now, anything still in progress, like a media upload, stops and won't be added to your post.",
        comment:
            "Message of an alert shown when closing the editor for a post while something, like a media upload, is in progress"
    )
    static let leavePageWhileNotReadyMessage = NSLocalizedString(
        "postEditor.notReadyAlert.leavePageMessage",
        value:
            "If you leave now, anything still in progress, like a media upload, stops and won't be added to your page.",
        comment:
            "Message of an alert shown when closing the editor for a page while something, like a media upload, is in progress"
    )
    static let savePostWhileNotReadyMessage = NSLocalizedString(
        "postEditor.notReadyAlert.savePostMessage",
        value:
            "Something in the editor, like a media upload, is still in progress. If you continue, it may be missing or broken in your post.",
        comment:
            "Message of an alert shown when saving, publishing or previewing a post while something, like a media upload, is in progress"
    )
    static let savePageWhileNotReadyMessage = NSLocalizedString(
        "postEditor.notReadyAlert.savePageMessage",
        value:
            "Something in the editor, like a media upload, is still in progress. If you continue, it may be missing or broken in your page.",
        comment:
            "Message of an alert shown when saving, publishing or previewing a page while something, like a media upload, is in progress"
    )
    static let leave = NSLocalizedString(
        "postEditor.notReadyAlert.leave",
        value: "Leave",
        comment: "Button to close the editor in an alert shown while something, like a media upload, is in progress"
    )
    static let continueAnyway = NSLocalizedString(
        "postEditor.notReadyAlert.continue",
        value: "Continue",
        comment:
            "Button to save, publish or preview anyway in an alert shown while something, like a media upload, is in progress"
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
