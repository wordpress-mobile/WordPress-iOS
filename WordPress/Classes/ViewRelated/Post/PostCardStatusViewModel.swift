import UIKit
import Gridicons

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject {
    private let post: Post
    private var progressObserverUUID: UUID? = nil
    @objc var progressBlock: ((Double) -> Void)? = nil {
        didSet {
            if let _ = oldValue, let uuid = progressObserverUUID {
                MediaCoordinator.shared.removeObserver(withUUID: uuid)
            }

            if let progressBlock = progressBlock {
                progressObserverUUID = MediaCoordinator.shared.addObserver({ [weak self] (_, _) in
                    if let post = self?.post {
                        progressBlock(MediaCoordinator.shared.totalProgress(for: post))
                    }
                }, forMediaFor: post)
            }
        }
    }

    @objc
    init(post: Post) {
        self.post = post
        super.init()
    }

    @objc
    var status: String? {
        if MediaCoordinator.shared.isUploadingMedia(for: post) {
            return NSLocalizedString("Uploading media...", comment: "Message displayed on a post's card while the post is uploading media")
        } else if post.isFailed {
            return NSLocalizedString("Upload failed", comment: "Message displayed on a post's card when the post has failed to upload")
        } else if post.remoteStatus == .pushing {
            return NSLocalizedString("Uploading post...", comment: "Message displayed on a post's card when the post has failed to upload")
        } else {
            return post.statusForDisplay()
        }
    }

    private var postStatus: BasePost.Status? {
        return post.status
    }

    @objc
    var shouldHideStatusView: Bool {
        guard let status = status else {
            return true
        }

        return status.count == 0
    }

    @objc
    var statusImage: UIImage? {
        guard let status = postStatus else {
            return nil
        }

        // In progress uploads
        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return Gridicon.iconOfType(.cloudUpload)
        }

        if post.isFailed {
            return Gridicon.iconOfType(.cloudUpload)
        }

        switch status {
        case .pending:
            return Gridicon.iconOfType(.chat)
        case .scheduled:
            return Gridicon.iconOfType(.scheduled)
        case .trash:
            return Gridicon.iconOfType(.trash)
        default:
            return UIDevice.isPad() ? Gridicon.iconOfType(.tablet) : Gridicon.iconOfType(.phone)
        }
    }

    @objc
    var statusColor: UIColor {
        guard let status = postStatus else {
            return .neutral(shade: .shade700)
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return .neutral(shade: .shade300)
        }

        if post.isFailed {
            return .error
        }

        switch status {
        case .pending:
            return .success
        case .scheduled:
            return .primary(shade: .shade400)
        case .trash:
            return .error
        default:
            return .neutral(shade: .shade700)
        }
    }

    @objc
    var shouldHideProgressView: Bool {
        return !(MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing)
    }

    @objc
    var progress: Double {
        if post.remoteStatus == .pushing {
            return 1.0
        } else {
            return MediaCoordinator.shared.totalProgress(for: post)
        }
    }
}
