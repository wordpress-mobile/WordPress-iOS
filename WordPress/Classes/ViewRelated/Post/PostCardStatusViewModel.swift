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
        case cancel
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
            if canCancelAutoUpload {
                return StatusMessages.postWillBePublished
            }

            return StatusMessages.uploadFailed
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
            return .neutral(shade: .shade70)
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return .neutral(shade: .shade30)
        }

        if post.isFailed {
            return canCancelAutoUpload ? .warning : .error
        }

        switch status {
        case .pending:
            return .success
        case .scheduled:
            return .primary(shade: .shade40)
        case .trash:
            return .error
        default:
            return .neutral(shade: .shade70)
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

    private var allButtons: [Button] {
        var buttons = [Button]()

        buttons.append(.edit)

        if !post.isFailed {
            buttons.append(.view)
        }

        if autoUploadInteractor.canRetryUpload(of: post) {
            buttons.append(.retry)
        }

        if canCancelAutoUpload {
            buttons.append(.cancel)
        }

        if canPublish {
            buttons.append(.publish)
        }

        if post.status == .publish {
            buttons.append(.stats)
        }

        buttons.append(.trash)

        return buttons
    }

    var primaryButtons: [Button] {
        let max = PostCardStatusViewModel.maximumPrimaryButtons
        var buttons = self.allButtons

        if buttons.count > max {
            buttons.insert(.more, at: max - 1)
            return Array(buttons.prefix(max))
        } else {
            return buttons
        }
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

    private enum Constants {
        static let stickyLabel = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
    }

    enum StatusMessages {
        static let uploadFailed = NSLocalizedString("Upload failed", comment: "Message displayed on a post's card when the post has failed to upload")
        static let postWillBePublished = NSLocalizedString("Post will be published next time your device is online",
                                                           comment: "Message shown in the posts list when a post is scheduled for publishing")
    }
}
