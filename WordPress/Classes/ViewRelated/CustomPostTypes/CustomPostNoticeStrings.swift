import Foundation

/// Localized titles for the success notices emitted when a custom post is
/// persisted to the server. Shared between the editor, the publishing sheet,
/// and the Custom Posts list.
enum CustomPostNoticeStrings {
    static let draftSaved = NSLocalizedString(
        "customPost.notice.draftSaved",
        value: "Draft saved",
        comment: "Success notice shown after a new draft custom post is created on the server."
    )
    static let postUpdated = NSLocalizedString(
        "customPost.notice.postUpdated",
        value: "Post updated",
        comment: "Success notice shown after an existing custom post is updated on the server."
    )
    static let postPublished = NSLocalizedString(
        "customPost.notice.postPublished",
        value: "Post published",
        comment: "Success notice shown after a custom post is published on the server."
    )
}
