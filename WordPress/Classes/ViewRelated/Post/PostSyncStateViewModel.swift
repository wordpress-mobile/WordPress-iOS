import Foundation

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
    private let isInternetReachable: Bool
    private let isSyncPublishingEnabled: Bool

    init(post: AbstractPost,
         isInternetReachable: Bool = ReachabilityUtils.isInternetReachable(),
         isSyncPublishingEnabled: Bool = FeatureFlag.syncPublishing.enabled) {
        self.post = post
        self.isInternetReachable = isInternetReachable
        self.isSyncPublishingEnabled = isSyncPublishingEnabled
    }

    var state: State {
        guard isSyncPublishingEnabled else {
            return _state
        }

        if PostCoordinator.shared.isDeleting(post) || PostCoordinator.shared.isUpdating(post) {
            return .uploading
        }
        if let error = PostCoordinator.shared.syncError(for: post.original()) {
            if PostCoordinator.isTerminalError(error) {
                return .failed
            }
            if let urlError = (error as NSError).underlyingErrors.first as? URLError,
               urlError.code == .notConnectedToInternet {
                return .offlineChanges // A better indicator on what's going on
            }
        }
        if PostCoordinator.shared.isSyncNeeded(for: post) {
            return .syncing
        }
        return .idle
    }

    /// - note: Deprecated (kahu-offline-mode)
    private var _state: State {
        if post.remoteStatus == .pushing || PostCoordinator.shared.isDeleting(post) || PostCoordinator.shared.isUpdating(post) {
            return .uploading
        }
        if post.isFailed {
            return isInternetReachable ? .failed : .offlineChanges
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
            return (UIImage(systemName: "wifi.slash"), UIColor.listIcon)
        case .failed:
            return (UIImage.gridicon(.notice), UIColor.error)
        case .idle, .uploading, .syncing:
            return nil
        }
    }

    var statusMessage: String? {
        guard isSyncPublishingEnabled else {
            return nil
        }
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
