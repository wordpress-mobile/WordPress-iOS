
import Foundation

/// Decides what action should happen for post when it is auto-uploaded.
final class PostAutoUploadInteractor {
    enum AutoUploadAction {
        /// Upload the post as is.
        ///
        /// For example, if the post was published locally, it will be published when the server receives it.
        case upload
        /// Upload a revision to the server.
        case autoSave
        case nothing
    }

    private static let allowedStatuses: [BasePost.Status] = [.draft, .publish]

    /// Returns what action should be executed when we retry a failed upload.
    ///
    /// In some cases, we do not want to automatically upload a post if the user has not
    /// given explicit confirmation. Users "confirm" automatic uploads by pressing the
    /// Publish or Update button in the editor.
    ///
    /// If we do not receive a confirmation, which can happen if the editor crashed, we will
    /// try to upload a revision instead.
    func autoUploadAction(for post: AbstractPost) -> AutoUploadAction {
        guard post.isFailed,
            let status = post.status,
            PostAutoUploadInteractor.allowedStatuses.contains(status),
            !post.hasRemote() else {
                return .nothing
        }

        if post.isLocalDraft || post.shouldAttemptAutoUpload() {
            return .upload
        } else {
            // TODO This is currently not supported by PostCoordinator
            return .autoSave
        }
    }

    /// Returns true if the post will be automatically uploaded later and it can be canceled.
    ///
    /// This can be used to determine if the app should show the Cancel button in the Post List.
    ///
    /// - SeeAlso: autoUploadAction(for:)
    func canCancelAutoUpload(of post: AbstractPost) -> Bool {
        guard autoUploadAction(for: post) == .upload else {
            return false
        }

        // Local drafts are always automatically uploaded
        return !post.isLocalDraft
    }

    /// Temporary method to support old _Retry_ upload functionality.
    ///
    /// This is going to be removed later. 
    func canRetryUpload(of post: AbstractPost) -> Bool {
        guard post.isFailed,
            let status = post.status else {
                return false
        }

        return !PostAutoUploadInteractor.allowedStatuses.contains(status)
    }
    
    
    /// Returns true if any of the following conditions are true:
    ///
    /// * The post is a draft.
    /// * The post failed to upload and has local changes but the user canceled auto-uploading
    /// * The upload failed and the user cannot Cancel it anymore. This happens when we reached the maximum number of retries.
    func canPublish(of post: AbstractPost) -> Bool {
        let isNotCancelablePublishedWithFailedToUploadChanges: Bool = post.isFailed && post.hasLocalChanges() && !canCancelAutoUpload(of: post)
        return post.isDraft() || isNotCancelablePublishedWithFailedToUploadChanges
    }
}
