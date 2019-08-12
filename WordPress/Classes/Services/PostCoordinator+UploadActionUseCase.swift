
import Foundation

extension PostCoordinator {
    enum UploadAction {
        case upload
        case remoteAutoSave
        case nothing
    }

    final class UploadActionUseCase {
        private static let allowedStatuses: [BasePost.Status] = [.draft, .publish]

        func getAutoUploadAction(post: AbstractPost) -> UploadAction {
            guard let status = post.status else {
                return .nothing
            }
            guard UploadActionUseCase.allowedStatuses.contains(status), !post.hasRemote() else {
                return .nothing
            }

            if post.confirmedAutoUpload {
                return .upload
            } else {
                return .remoteAutoSave
            }
        }

        func canCancelAutoUpload(of post: AbstractPost) -> Bool {
            guard post.isFailed else {
                return false
            }
            guard let status = post.status else {
                return false
            }
            // Ignore currently not supported statuses
            guard UploadActionUseCase.allowedStatuses.contains(status) else {
                return false
            }

            // Local drafts are always automatically uploaded
            if post.status == .draft && !post.hasRemote() {
                return false
            } else {
                return getAutoUploadAction(post: post) == .upload && post.confirmedAutoUpload
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
