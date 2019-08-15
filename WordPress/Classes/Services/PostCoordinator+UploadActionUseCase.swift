
import Foundation

extension PostCoordinator {
    enum UploadAction {
        /// Upload the post as is.
        ///
        /// For example, if the post was published locally, it will be published when the server receives it.
        case upload
        /// Upload a revision to the server.
        case autoSave
        case nothing
    }

    /// Provides business logic for automatic uploads.
    final class UploadActionUseCase {
        private static let allowedStatuses: [BasePost.Status] = [.draft, .publish]

        /// Returns what action should be executed when we retry a failed upload.
        ///
        /// In some cases, we do not want to automatically upload a post if the user has not
        /// given explicit confirmation. Users "confirm" automatic uploads by pressing the
        /// Publish or Update button in the editor.
        ///
        /// If we do not receive a confirmation, which can happen if the editor crashed, we will
        /// try to upload a revision instead.
        func autoUploadAction(for post: AbstractPost) -> UploadAction {
            guard post.isFailed else {
                return .nothing
            }
            guard let status = post.status else {
                return .nothing
            }
            guard UploadActionUseCase.allowedStatuses.contains(status), !post.hasRemote() else {
                return .nothing
            }

            if post.isLocalDraft || post.confirmedAutoUpload {
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
            if post.isLocalDraft {
                return false
            } else {
                return post.confirmedAutoUpload
            }
        }

        /// Temporary method to support old _Retry_ upload functionality.
        func canRetryUpload(of post: AbstractPost) -> Bool {
            guard post.isFailed else {
                return false
            }
            guard let status = post.status else {
                return false
            }

            return !UploadActionUseCase.allowedStatuses.contains(status)
        }
    }
}

extension AbstractPost {
    private static let confirmedPrefix = "<C> "

    #warning("Stub. This should be replaced by a content hash.")
    var confirmedAutoUpload: Bool {
        get {
            return postTitle?.hasPrefix(AbstractPost.confirmedPrefix) ?? false
        }
        set {
            let title = postTitle ?? ""

            if newValue {
                if !title.hasPrefix(AbstractPost.confirmedPrefix) {
                    postTitle = AbstractPost.confirmedPrefix + title
                }
            } else {
                if title.hasPrefix(AbstractPost.confirmedPrefix) {
                    postTitle = title.removingPrefix(AbstractPost.confirmedPrefix)
                }
            }
        }
    }
}
