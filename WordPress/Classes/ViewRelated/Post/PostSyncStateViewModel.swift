import Foundation

final class PostSyncStateViewModel {
    enum State {
        case idle
        case syncing
        case offlineChanges
        case failed
    }

    private let post: Post
    private let isInternetReachable: Bool

    var state: State {
        if post.remoteStatus == .pushing || PostCoordinator.shared.isDeleting(post) {
            return .syncing
        }
        if post.isFailed {
            return isInternetReachable ? .failed : .offlineChanges
        }
        return .idle
    }

    var isEditable: Bool {
        state == .idle || state == .offlineChanges || state == .failed
    }

    var isShowingEllipsis: Bool {
        isEditable
    }

    var isShowingIcon: Bool {
        state == .offlineChanges || state == .failed
    }

    var isShowingIndicator: Bool {
        state == .syncing
    }

    var iconInfo: (image: UIImage?, color: UIColor)? {
        switch state {
        case .offlineChanges:
            return (UIImage(systemName: "wifi.slash"), UIColor.listIcon)
        case .failed:
            return (UIImage.gridicon(.notice), UIColor.error)
        case .idle, .syncing:
            return nil
        }
    }

    var statusMessage: String? {
        switch state {
        case .offlineChanges:
            return Strings.offlineChanges
        case .failed, .idle, .syncing:
            return nil
        }
    }

    init(post: Post, isInternetReachable: Bool = ReachabilityUtils.isInternetReachable()) {
        self.post = post
        self.isInternetReachable = isInternetReachable
    }
}

private enum Strings {
    static let offlineChanges = NSLocalizedString(
        "postList.offlineChanges",
        value: "Offline changes",
        comment: "Label for a post in the post list. Indicates that the post has offline changes."
    )
}
