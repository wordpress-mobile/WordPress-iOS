
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

            return .upload
        }
    }
}
