
import Foundation

/// Decides what action should happen for post when it is auto-uploaded.
final class PostAutoUploadInteractor {
    enum AutoUploadAction: String {
        /// Upload the post as is.
        ///
        /// For example, if the post was published locally, it will be published when the server receives it.
        case upload = "upload"
        /// Upload a revision to the server.
        ///
        /// This is used for non-self-hosted sites. If the post does not exist on the server yet,
        /// the post will be created as a draft. Please see `PostService.autoSave()` for more info
        /// on how the decision process works.
        case autoSave = "autoSave"
        /// Upload a local post as a draft, regardless of the `.status`.
        ///
        /// This is used for self-hosted sites only and is primarily used to save locally
        /// published posts that are not confirmed for auto-uploading. In this scenario, we will
        /// still upload the post to the server but as a draft.
        case uploadAsDraft = "uploadAsDraft"
        /// Ignore the post.
        case nothing = "nothing"
    }

    enum AutoUploadAttemptState {
        case attempted
        case reachedLimit
        case notAttempted
    }

    private static let disallowedStatuses: [BasePost.Status] = [.trash, .deleted]

    private static let maxNumberOfAttempts = 3

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
            !PostAutoUploadInteractor.disallowedStatuses.contains(status),
            !(post is Page),
            post.autoUploadAttemptsCount.intValue < PostAutoUploadInteractor.maxNumberOfAttempts else {
                return .nothing
        }

        if post.isLocalDraft || post.shouldAttemptAutoUpload {
            return .upload
        } else if post.blog.supports(.wpComRESTAPI) {
            return .autoSave
        } else if !post.hasRemote() {
            return .uploadAsDraft
        } else {
            return .nothing
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

        return PostAutoUploadInteractor.disallowedStatuses.contains(status)
    }

    /// Returns what is the auto upload attempt state for a given post
    ///
    func autoUploadAttemptState(of post: AbstractPost) -> AutoUploadAttemptState {
        let autoUploadAttemptsCount = post.autoUploadAttemptsCount.intValue
        if autoUploadAttemptsCount >= PostAutoUploadInteractor.maxNumberOfAttempts {
            return .reachedLimit
        } else if autoUploadAttemptsCount > 0 {
            return .attempted
        } else {
            return .notAttempted
        }
    }
}
