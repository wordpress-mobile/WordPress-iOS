import UIKit
import Gridicons

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject, AbstractPostMenuViewModel {

    let post: Post
    private var progressObserverUUID: UUID? = nil

    private let autoUploadInteractor = PostAutoUploadInteractor()

    private let isInternetReachable: Bool
    private let isJetpackFeaturesEnabled: Bool
    private let isBlazeFlagEnabled: Bool
    private let isSyncPublishingEnabled: Bool

    /// - warning: deprecated (kahu-offline-mode)
    var progressBlock: ((Float) -> Void)? = nil {
        didSet {
            if let _ = oldValue, let uuid = progressObserverUUID {
                MediaCoordinator.shared.removeObserver(withUUID: uuid)
            }

            if let progressBlock = progressBlock {
                progressObserverUUID = MediaCoordinator.shared.addObserver({ [weak self] (_, _) in
                    if let post = self?.post {
                        progressBlock(Float(MediaCoordinator.shared.totalProgress(for: post)))
                    }
                }, forMediaFor: post)
            }
        }
    }

    init(post: Post,
         isInternetReachable: Bool = ReachabilityUtils.isInternetReachable(),
         isJetpackFeaturesEnabled: Bool = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
         isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled(),
         isSyncPublishingEnabled: Bool = RemoteFeatureFlag.syncPublishing.enabled()) {
        self.post = post
        self.isInternetReachable = isInternetReachable
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
        self.isSyncPublishingEnabled = isSyncPublishingEnabled
        super.init()
    }

    var status: String? {
        guard isSyncPublishingEnabled else {
            return _status
        }
        if post.isLegacyUnsavedRevision {
            return StatusMessages.localChanges
        }
        return nil
    }

    /// - note: Deprecated (kahu-offline-mode)
    private var _status: String? {
        // TODO Move these string constants to the StatusMessages enum
        if MediaCoordinator.shared.isUploadingMedia(for: post) {
            return NSLocalizedString("Uploading media...", comment: "Message displayed on a post's card while the post is uploading media")
        } else if PostCoordinator.shared.isDeleting(post) {
            return post.status == .trash ? Strings.deletingPostPermanently : Strings.movingPostToTrash
        } else if post.isFailed {
            return generateFailedStatusMessage()
        } else if post.remoteStatus == .pushing {
            return NSLocalizedString("Uploading post...", comment: "Message displayed on a post's card when the post has failed to upload")
        } else if !post.hasLocalChanges() && post.hasAutosaveRevision {
            return StatusMessages.hasUnsavedChanges
        } else {
            return post.statusForDisplay()
        }
    }

    var author: String {
        guard let author = post.authorForDisplay() else {
            return ""
        }

        return author
    }

    var isUploadingOrFailed: Bool {
        return MediaCoordinator.shared.isUploadingMedia(for: post) || post.isFailed || post.remoteStatus == .pushing
    }

    private var postStatus: BasePost.Status? {
        return post.status
    }

    var statusColor: UIColor {
        guard isSyncPublishingEnabled else {
            return _statusColor
        }
        if post.isLegacyUnsavedRevision {
            return .warning
        }
        switch post.status ?? .draft {
        case .pending:
            return .success
        case .scheduled:
            return .primary(.shade40)
        case .trash:
            return .error
        default:
            return .neutral(.shade70)
        }
    }

    /// - warning: deprecated (kahu-offline-mode)
    var _statusColor: UIColor {
        guard let status = postStatus else {
            return .neutral(.shade70)
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return .neutral(.shade30)
        }

        if PostCoordinator.shared.isDeleting(post) {
            return .systemRed
        }

        if post.isFailed && isInternetReachable {
            return .error
        }

        if post.isRevision() {
            return post.hasPermanentFailedMedia() ? .error : .warning
        }

        if post.isFailed {
            let autoUploadAction = autoUploadInteractor.autoUploadAction(for: post)
            return (autoUploadAction == .upload || post.wasAutoUploadCancelled) ? .warning : .error
        }

        if post.hasAutosaveRevision {
            return .warning(.shade40)
        }

        switch status {
        case .pending:
            return .success
        case .scheduled:
            return .primary(.shade40)
        case .trash:
            return .error
        default:
            return .neutral(.shade70)
        }
    }

    var shouldHideProgressView: Bool {
        if isSyncPublishingEnabled {
            return true
        }
        return !(MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing)
    }

    var progress: Float {
        if post.remoteStatus == .pushing {
            return 1.0
        } else {
            return Float(MediaCoordinator.shared.totalProgress(for: post))
        }
    }

    /// Returns what buttons are visible
    var buttonSections: [AbstractPostButtonSection] {
        return [
            createPrimarySection(),
            createSecondarySection(),
            createBlazeSection(),
            createNavigationSection(),
            createTrashSection()
        ]
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isSyncPublishingEnabled {
            if post.status != .trash {
                buttons.append(.view)
            }
        } else {
            if !post.isFailed && post.status != .trash {
                buttons.append(.view)
            }
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createSecondarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if canPublish {
            buttons.append(.publish)
        }

        if post.status != .draft {
            buttons.append(.moveToDraft)
        }

        if post.status == .publish || post.status == .draft || post.status == .pending {
            buttons.append(.duplicate)
        }

        if post.status == .publish && post.hasRemote() {
            buttons.append(.share)
        }

        if !isSyncPublishingEnabled {
            if autoUploadInteractor.canRetryUpload(of: post) ||
                autoUploadInteractor.autoUploadAttemptState(of: post) == .reachedLimit ||
                post.isFailed && isInternetReachable {
                buttons.append(.retry)
            }

            if canCancelAutoUpload && !isInternetReachable {
                buttons.append(.cancelAutoUpload)
            }
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createBlazeSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isBlazeFlagEnabled && post.canBlaze {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .postsList)
            buttons.append(.blaze)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createNavigationSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isJetpackFeaturesEnabled, post.status == .publish && post.hasRemote() {
            buttons.append(contentsOf: [.stats, .comments])
        }
        if post.status != .trash {
            buttons.append(.settings)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createTrashSection() -> AbstractPostButtonSection {
        let action: AbstractPostButton = post.original().status == .trash ? .delete : .trash
        return AbstractPostButtonSection(buttons: [action])
    }

    private var canCancelAutoUpload: Bool {
        return autoUploadInteractor.canCancelAutoUpload(of: post)
    }

    private var canPublish: Bool {
        guard isSyncPublishingEnabled else {
            return _canPublish
        }
        let userCanPublish = post.blog.capabilities != nil ? post.blog.isPublishingPostsAllowed() : true
        return (post.status == .draft || post.status == .pending) && userCanPublish
    }

    /// - warning: deprecated (kahu-offline-mode)
    private var _canPublish: Bool {
        let isNotCancelableWithFailedToUploadChanges: Bool = post.isFailed && post.hasLocalChanges() && !autoUploadInteractor.canCancelAutoUpload(of: post)
        return post.isDraft() || isNotCancelableWithFailedToUploadChanges
    }

    func statusAndBadges(separatedBy separator: String) -> String {
        let sticky = post.isStickyPost ? Constants.stickyLabel : ""
        let pending = (post.status == .pending && isSyncPublishingEnabled) ? Constants.pendingReview : ""
        let status = self.status ?? ""

        return [status, pending, sticky].filter { !$0.isEmpty }.joined(separator: separator)
    }

    /// Determine what the failed status message should be and return it.
    ///
    /// This is a helper method for `status`.
    private func generateFailedStatusMessage() -> String {

        let postAutoUploadMessages = PostAutoUploadMessages(for: post, onlineFailedUploadMessage: StatusMessages.uploadFailed)

        if post.wasAutoUploadCancelled {
            return post.hasPermanentFailedMedia() ? postAutoUploadMessages.failedMediaUploadMessage(for: post.status) : StatusMessages.localChanges
        }

        return postAutoUploadMessages.failedUploadMessage(
            isInternetReachable: isInternetReachable,
            autoUploadState: autoUploadInteractor.autoUploadAttemptState(of: post),
            autoUploadAction: autoUploadInteractor.autoUploadAction(for: post))
    }

    private enum Constants {
        static let stickyLabel = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
        static let pendingReview = NSLocalizedString("postList.badgePendingReview", value: "Pending review", comment: "Badge for post cells")
    }

    enum StatusMessages {
        static let uploadFailed = NSLocalizedString("Upload failed",
                                                            comment: "Message displayed on a post's card when the post has failed to upload")
        static let localChanges = NSLocalizedString("Local changes",
                                                            comment: "A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.")
        static let hasUnsavedChanges = NSLocalizedString("You've made unsaved changes to this post",
                                                            comment: "Message displayed on a post's card when the post has unsaved changes")
    }
}

private enum Strings {
    static let movingPostToTrash = NSLocalizedString("post.movingToTrashStatusMessage", value: "Moving post to trash...", comment: "Status mesasge for post cells")
    static let deletingPostPermanently = NSLocalizedString("post.deletingPostPermanentlyStatusMessage", value: "Deleting post...", comment: "Status mesasge for post cells")
}
