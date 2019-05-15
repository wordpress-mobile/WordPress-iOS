import UIKit
import Gridicons

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject {
    private let post: Post
    private var progressObserverUUID: UUID? = nil
    @objc var progressBlock: ((Float) -> Void)? = nil {
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
        } else if post.status == BasePost.Status.trash || post.status == BasePost.Status.scheduled {
            return ""
        } else {
            return post.statusForDisplay()
        }
    }

    var isUploadingOrFailed: Bool {
        return MediaCoordinator.shared.isUploadingMedia(for: post) || post.isFailed || post.remoteStatus == .pushing
    }

    var shouldShowStickyLabel: Bool {
        return post.isStickyPost && !isUploadingOrFailed
    }

    private var postStatus: BasePost.Status? {
        return post.status
    }

    @objc
    var shouldHideStatusView: Bool {
        guard let status = status else {
            return !post.isStickyPost
        }

        return status.isEmpty && !post.isStickyPost
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
            return WPStyleGuide.jazzyOrange()
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing {
            return WPStyleGuide.grey()
        }

        if post.isFailed {
            return WPStyleGuide.errorRed()
        }

        switch status {
        case .pending:
            return WPStyleGuide.jazzyOrange()
        case .scheduled:
            return WPStyleGuide.mediumBlue()
        case .trash:
            return WPStyleGuide.errorRed()
        default:
            return WPStyleGuide.jazzyOrange()
        }
    }

    @objc
    var shouldHideProgressView: Bool {
        return !(MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing)
    }

    @objc
    var progress: Float {
        if post.remoteStatus == .pushing {
            return 1.0
        } else {
            return Float(MediaCoordinator.shared.totalProgress(for: post))
        }
    }
}
