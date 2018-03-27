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
        if MediaCoordinator.shared.isUploadingMedia(for: post) {
            return Gridicon.iconOfType(.cloudUpload)
        }

        // Failed uploads
        if post.remoteStatus == .failed || MediaCoordinator.shared.hasFailedMedia(for: post) {
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
            return WPStyleGuide.darkGrey()
        }

        if MediaCoordinator.shared.isUploadingMedia(for: post) {
            return WPStyleGuide.grey()
        }

        if post.remoteStatus == .failed || MediaCoordinator.shared.hasFailedMedia(for: post) {
            return WPStyleGuide.errorRed()
        }

        switch status {
        case .pending:
            return WPStyleGuide.validGreen()
        case .scheduled:
            return WPStyleGuide.mediumBlue()
        case .trash:
            return WPStyleGuide.errorRed()
        default:
            return WPStyleGuide.darkGrey()
        }
    }

    @objc
    var shouldHideProgressView: Bool {
        return !MediaCoordinator.shared.isUploadingMedia(for: post)
    }

    var progress: Double {
        return MediaCoordinator.shared.totalProgress(for: post)
    }
}
