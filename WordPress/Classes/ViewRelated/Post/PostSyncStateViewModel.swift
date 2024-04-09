import Foundation

final class PostSyncStateViewModel {
    enum State {
        case idle
        // Has unsynced changes
        case unsynced
        case uploading
        case offlineChanges
        case failed
    }

    private let post: AbstractPost
    private let isInternetReachable: Bool
    private let isSyncPublishingEnabled: Bool

    init(post: AbstractPost,
         isInternetReachable: Bool = ReachabilityUtils.isInternetReachable(),
         isSyncPublishingEnabled: Bool = RemoteFeatureFlag.syncPublishing.enabled()) {
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
            if let saveError = error as? PostRepository.PostSaveError,
               case .conflict = saveError {
                return .failed // Terminal error
            }
            if let urlError = (error as NSError).underlyingErrors.first as? URLError,
               urlError.code == .notConnectedToInternet {
                return .offlineChanges // A better indicator on what's going on
            }
        }
        if PostCoordinator.shared.isSyncNeeded(for: post) {
            return .unsynced
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
        state == .uploading || state == .unsynced
    }

    var iconInfo: (image: UIImage?, color: UIColor)? {
        switch state {
        case .offlineChanges:
            return (UIImage(systemName: "wifi.slash"), UIColor.listIcon)
        case .failed:
            return (UIImage.gridicon(.notice), UIColor.error)
        case .idle, .uploading, .unsynced:
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
        case .failed, .idle, .uploading, .unsynced:
            return nil
        }
    }
}

private enum Strings {
    static let offlineChanges = NSLocalizedString("postList.offlineChanges", value: "Offline changes", comment: "Label for a post in the post list. Indicates that the post has offline changes.")
}
