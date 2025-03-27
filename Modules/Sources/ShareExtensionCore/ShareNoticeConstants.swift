import WordPressShared

/// A collection of notification constants shared between the app extensions
/// and WPiOS.
///
public enum ShareNoticeConstants {
    public static let notificationSourceSuccess = "share_success_notification"
    public static let categorySuccessIdentifier = "share-upload-success"
    public static let categoryFailureIdentifier = "share-upload-failure"
}

public enum ShareNoticeUserInfoKey {
    public static let blogID = "blog_id"
    public static let postID = "post_id"
    public static let postUploadOpID = "post_upload_op_id"
    public static let originatedFromAppExtension = "originated_from_app_extension"
}

public struct ShareNoticeText {
    public static let actionEditPost = AppLocalizedString("Edit Post", comment: "Button title. Opens the editor to edit an existing post.")

    public static let successDraftTitleDefault = AppLocalizedString("1 draft post uploaded", comment: "Local notification displayed to the user when a single draft post has been successfully uploaded.")
    public static let successTitleDefault = AppLocalizedString("1 post uploaded", comment: "Alert displayed to the user when a single post has been successfully uploaded.")
    public static let successDraftTitleSingular = AppLocalizedString("Uploaded 1 draft post, 1 file", comment: "Local notification displayed to the user when a single draft post and 1 file has been uploaded successfully.")
    public static let successTitleSingular = AppLocalizedString("Uploaded 1 post, 1 file", comment: "System notification displayed to the user when a single post and 1 file has uploaded successfully.")
    public static let successDraftTitlePlural = AppLocalizedString("Uploaded 1 draft post, %ld files", comment: "Local notification displayed to the user when a single draft post and multiple files have uploaded successfully.")
    public static let successTitlePlural = AppLocalizedString("Uploaded 1 post, %ld files", comment: "System notification displayed to the user when a single post and multiple files have uploaded successfully.")

    public static let failureTitleDefault = AppLocalizedString("Unable to upload 1 post", comment: "Alert displayed to the user when a single post has failed to upload.")
    public static let failureTitleSingular = AppLocalizedString("Unable to upload 1 post, 1 file", comment: "Alert displayed to the user when a single post and 1 file has failed to upload.")
    public static let failureTitlePlural = AppLocalizedString("Unable to upload 1 post, %ld files", comment: "Alert displayed to the user when a single post and multiple files have failed to upload.")

    /// Helper method to provide the formatted version of a success title based on the media item count.
    ///
    public static func successTitle(mediaItemCount: Int = 0, postStatus: String) -> String {
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
    public static func failureTitle(mediaItemCount: Int = 0) -> String {
        if mediaItemCount == 0 {
            return failureTitlePlural
        } else {
            return pluralize(mediaItemCount, singular: failureTitleSingular, plural: failureTitlePlural)
        }
    }

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    public static func pluralize(_ count: Int, singular: String, plural: String) -> String {
        if count == 1 {
            return singular
        } else {
            return String(format: plural, count)
        }
    }

    public struct Constants {
        public static let draftStatus = "draft"
    }
}
