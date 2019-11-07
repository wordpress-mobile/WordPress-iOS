import UIKit
import Gridicons

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject {
    private static let maximumPrimaryButtons = 3

    enum Button {
        case edit
        case retry
        case view
        case more
        case publish
        case stats
        case moveToDraft
        case trash
        case cancelAutoUpload
    }

    struct ButtonGroups: Equatable {
        /// The main buttons shown in the Post List
        let primary: [Button]
        /// Shown under the _More_
        let secondary: [Button]
    }

    let post: Post
    private var progressObserverUUID: UUID? = nil

    private let autoUploadInteractor = PostAutoUploadInteractor()

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

    init(post: Post) {
        self.post = post
        super.init()
    }

    private var status: String? {
        // TODO Move these string constants to the StatusMessages enum
        if MediaCoordinator.shared.isUploadingMedia(for: post) {
            return NSLocalizedString("Uploading media...", comment: "Message displayed on a post's card while the post is uploading media")
        } else if post.isFailed {
            return generateFailedStatusMessage()
        } else if post.remoteStatus == .pushing {
            return NSLocalizedString("Uploading post...", comment: "Message displayed on a post's card when the post has failed to upload")
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
        guard let status = postStatus else {
            return .neutral(.shade70)
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return .neutral(.shade30)
        }

        if post.isRevision() {
            return post.hasPermanentFailedMedia() ? .error : .warning
        }

        if post.isFailed {
            let autoUploadAction = autoUploadInteractor.autoUploadAction(for: post)
            return (autoUploadAction == .upload || post.wasAutoUploadCancelled) ? .warning : .error
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
    ///
    /// The order matters here. For the primary buttons, we do not currently support dynamic
    /// buttons in the UI. Technically, we may end up with situations where there are no buttons
    /// visible. But we've carefully considered the possible situations so this does not happen.
    ///
    /// The order of the Buttons are important here, especially for the secondary buttons which
    /// dictate what buttons are shown in the action sheet after pressing _More_.
    var buttonGroups: ButtonGroups {
        let maxPrimaryButtons = PostCardStatusViewModel.maximumPrimaryButtons

        let allButtons: [Button] = {
            var buttons = [Button]()

            buttons.append(.edit)

            if !post.isFailed {
                buttons.append(.view)
            }

            if autoUploadInteractor.canRetryUpload(of: post) {
                buttons.append(.retry)
            }

            if canCancelAutoUpload {
                buttons.append(.cancelAutoUpload)
            }

            if autoUploadInteractor.autoUploadAttemptState(of: post) == .reachedLimit {
                buttons.append(.retry)
            }

            if canPublish {
                buttons.append(.publish)
            }

            if post.status == .publish && post.hasRemote() {
                buttons.append(.stats)
            }

            if post.status != .draft {
                buttons.append(.moveToDraft)
            }

            buttons.append(.trash)

            return buttons
        }()

        // If allButtons is [one, two, three, four], set the primary to [one, two, “more”].
        // If allButtons is [one, two, three], set the primary to the same.
        let primaryButtons: [Button] = {
            if allButtons.count <= maxPrimaryButtons {
                return allButtons
            }

            var primary = allButtons.prefix(maxPrimaryButtons - 1)
            primary.append(.more)
            return Array(primary)
        }()

        // If allButtons is [one, two, three, four], set the secondary to [three, four].
        // If allButtons is [one, two, three], set the secondary to [].
        let secondaryButtons: [Button] = {
            if allButtons.count > maxPrimaryButtons {
                return Array(allButtons.suffix(from: maxPrimaryButtons - 1))
            } else {
                return []
            }
        }()

        return ButtonGroups(primary: primaryButtons, secondary: secondaryButtons)
    }

    private var canCancelAutoUpload: Bool {
        return autoUploadInteractor.canCancelAutoUpload(of: post)
    }

    /// Returns true if any of the following conditions are true:
    ///
    /// * The post is a draft.
    /// * The post failed to upload and has local changes but the user canceled auto-uploading
    /// * The upload failed and the user cannot Cancel it anymore. This happens when we reached the maximum number of retries.
    private var canPublish: Bool {
        let isNotCancelableWithFailedToUploadChanges: Bool = post.isFailed && post.hasLocalChanges() && !autoUploadInteractor.canCancelAutoUpload(of: post)
        return post.isDraft() || isNotCancelableWithFailedToUploadChanges
    }

    func statusAndBadges(separatedBy separator: String) -> String {
        let sticky = post.isStickyPost && !isUploadingOrFailed ? Constants.stickyLabel : ""
        let status = self.status ?? ""

        return [status, sticky].filter { !$0.isEmpty }.joined(separator: separator)
    }

    /// Determine what the failed status message should be and return it.
    ///
    /// This is a helper method for `status`.
    private func generateFailedStatusMessage() -> String {
        let defaultFailedMessage = StatusMessages.uploadFailed

        guard post.isFailed, let postStatus = post.status else {
            return defaultFailedMessage
        }

        if post.wasAutoUploadCancelled {
            return post.hasPermanentFailedMedia() ? PostAutoUploadMessages.failedMedia : StatusMessages.localChanges
        }

        if let autoUploadMessage = PostAutoUploadMessages.attemptFailures(for: post, withState: autoUploadInteractor.autoUploadAttemptState(of: post)) {
            return autoUploadMessage
        }

        if autoUploadInteractor.autoUploadAction(for: post) != .upload {
            return defaultFailedMessage
        }

        switch postStatus {
        case .draft:
            return PostAutoUploadMessages.draftWillBeUploaded
        case .publishPrivate:
            return PostAutoUploadMessages.privateWillBeUploaded
        case .scheduled:
            return PostAutoUploadMessages.scheduledWillBeUploaded
        case .publish:
            return PostAutoUploadMessages.postWillBePublished
        default:
            return PostAutoUploadMessages.willSubmitLater
        }
    }

    private enum Constants {
        static let stickyLabel = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
    }

    enum StatusMessages {
        static let uploadFailed = NSLocalizedString("Upload failed",
                                                            comment: "Message displayed on a post's card when the post has failed to upload")
        static let localChanges = NSLocalizedString("Local changes",
                                                            comment: "A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.")
    }
}
