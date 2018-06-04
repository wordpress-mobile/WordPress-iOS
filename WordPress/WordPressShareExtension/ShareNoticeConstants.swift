/// A collection of notification constants shared between the app extensions
/// and WPiOS.
///
enum ShareNoticeConstants {
    static let notificationSourceSuccess = "share_success_notification"
    static let categorySuccessIdentifier = "share-upload-success"
    static let categoryFailureIdentifier = "share-upload-failure"
}

enum ShareNoticeUserInfoKey {
    static let blogID = "blog_id"
    static let postID = "post_id"
    static let postUploadOpID = "post_upload_op_id"
    static let originatedFromAppExtension = "originated_from_app_extension"
}

struct ShareNoticeText {
    static let actionEditPost       = NSLocalizedString("Edit Post", comment: "Button title. Opens the editor to edit an existing post.")

    static let successDraftTitleDefault = NSLocalizedString("1 draft post uploaded", comment: "Local notification displayed to the user when a single draft post has been successfully uploaded.")
    static let successTitleDefault  = NSLocalizedString("1 post uploaded", comment: "Alert displayed to the user when a single post has been successfully uploaded.")
    static let successDraftTitleSingular = NSLocalizedString("Uploaded 1 draft post, 1 file", comment: "Local notification displayed to the user when a single draft post and 1 file has been uploaded successfully.")
    static let successTitleSingular = NSLocalizedString("Uploaded 1 post, 1 file", comment: "System notification displayed to the user when a single post and 1 file has uploaded successfully.")
    static let successDraftTitlePlural = NSLocalizedString("Uploaded 1 draft post, %ld files", comment: "Local notification displayed to the user when a single draft post and multiple files have uploaded successfully.")
    static let successTitlePlural   = NSLocalizedString("Uploaded 1 post, %ld files", comment: "System notification displayed to the user when a single post and multiple files have uploaded successfully.")

    static let failureDraftTitleDefault = NSLocalizedString("Unable to upload 1 draft post", comment: "Alert displayed to the user when a single post has failed to upload.")
    static let failureTitleDefault  = NSLocalizedString("Unable to upload 1 post", comment: "Alert displayed to the user when a single post has failed to upload.")
    static let failureDraftTitleSingular = NSLocalizedString("Unable to upload 1 draft post, 1 file", comment: "Alert displayed to the user when a single post and 1 file has failed to upload.")
    static let failureTitleSingular = NSLocalizedString("Unable to upload 1 post, 1 file", comment: "Alert displayed to the user when a single post and 1 file has failed to upload.")
    static let failureDraftTitlePlural = NSLocalizedString("Unable to upload 1 draft post, %ld files", comment: "Alert displayed to the user when a single post and multiple files have failed to upload.")
    static let failureTitlePlural   = NSLocalizedString("Unable to upload 1 post, %ld files", comment: "Alert displayed to the user when a single post and multiple files have failed to upload.")

    /// Helper method to provide the formatted version of a success title based on the media item count.
    ///
    static func successTitle(mediaItemCount: Int = 0, postStatus: String) -> String {
        if mediaItemCount == 0 && postStatus == Constants.draftStatus {
            return successDraftTitleDefault
        }

        if mediaItemCount == 0 && postStatus != Constants.draftStatus {
            return successTitleDefault
        }

        if mediaItemCount > 0 && postStatus == Constants.draftStatus {
            return pluralize(mediaItemCount, singular: successDraftTitleSingular, plural: successDraftTitlePlural)
        }

        return pluralize(mediaItemCount, singular: successTitleSingular, plural: successTitlePlural)
    }

    /// Helper method to provide the formatted version of a failure title based on the media item count.
    ///
    static func failureTitle(mediaItemCount: Int = 0) -> String {
        if mediaItemCount == 0 {
            return failureTitlePlural
        } else {
            return pluralize(mediaItemCount, singular: failureTitleSingular, plural: failureTitlePlural)
        }
    }

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    static func pluralize(_ count: Int, singular: String, plural: String) -> String {
        if count == 1 {
            return singular
        } else {
            return String(format: plural, count)
        }
    }

    struct Constants {
        static let draftStatus = "draft"
    }
}
