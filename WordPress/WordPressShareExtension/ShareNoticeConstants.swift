/// A collection of notification constants shared between the app extensions
/// and WPiOS.
///
enum ShareNoticeConstants {
    static let notificationSourceSuccess = "share_success_notification"
    static let categorySuccessIdentifier = "share-upload-success"
    static let categoryFailureIdentifier = "share-upload-failure"
}

enum ShareNoticeText {
    static let actionEditPost       = NSLocalizedString("Edit Post", comment: "Button title. Opens the editor to edit an existing post.")

    static let successTitleDefault  = NSLocalizedString("1 post uploaded.", comment: "Alert displayed to the user when a single post has been successfully uploaded.")
    static let successTitleSingular = NSLocalizedString("Uploaded 1 post, 1 file.", comment: "System notification displayed to the user when a single post and 1 file has uploaded successfully.")
    static let successTitlePlural   = NSLocalizedString("Uploaded 1 post, %ld files.", comment: "System notification displayed to the user when a single post and multiple files have uploaded successfully.")

    static let failureTitleDefault  = NSLocalizedString("Unable to upload 1 post.", comment: "Alert displayed to the user when a single post has failed to upload.")
    static let failureTitleSingular = NSLocalizedString("Unable to upload 1 post, 1 file.", comment: "Alert displayed to the user when a single post and 1 file has failed to upload.")
    static let failureTitlePlural   = NSLocalizedString("Unable to upload 1 post, %ld files.", comment: "Alert displayed to the user when a single post and multiple files have failed to upload.")
}

enum ShareNoticeUserInfoKey {
    static let blogID = "blog_id"
    static let postID = "post_id"
}
