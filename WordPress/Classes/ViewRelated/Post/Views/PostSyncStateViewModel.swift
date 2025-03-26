import Foundation
import WordPressUI

final class PostSyncStateViewModel {
    enum State {
        case idle
        /// Syncing changes in the background.
        case syncing
        /// Actively updating the post: moving to trash, restoring, etc.
        case uploading
        case offlineChanges
        case failed
    }

    private let post: AbstractPost

    init(post: AbstractPost) {
        self.post = post
    }

    var state: State {
        if PostCoordinator.shared.isUpdating(post) {
            return .uploading
        }
        if let error = PostCoordinator.shared.syncError(for: post.original()) {
            if let urlError = (error as NSError).underlyingErrors.first as? URLError,
               urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                return .offlineChanges // A better indicator on what's going on
            } else {
                return .failed
            }
        }
        if PostCoordinator.shared.isSyncNeeded(for: post) {
            return .syncing
        }
        return .idle
    }

    var isEditable: Bool {
        state != .uploading
    }

    var isShowingEllipsis: Bool {
        isEditable
    }

    var isShowingIndicator: Bool {
        state == .uploading || state == .syncing
    }

    var iconInfo: (image: UIImage?, color: UIColor)? {
        switch state {
        case .offlineChanges:
            return (UIImage(systemName: "wifi.slash"), UIColor.secondaryLabel)
        case .failed:
            return (UIImage.gridicon(.notice), UIAppColor.error)
        case .idle, .uploading, .syncing:
            return nil
        }
    }

    var statusMessage: String? {
        switch state {
        case .offlineChanges:
            return Strings.offlineChanges
        case .failed, .idle, .uploading, .syncing:
            return nil
        }
    }
}

private enum Strings {
    static let offlineChanges = NSLocalizedString("postList.offlineChanges", value: "Offline changes", comment: "Label for a post in the post list. Indicates that the post has offline changes.")
}
