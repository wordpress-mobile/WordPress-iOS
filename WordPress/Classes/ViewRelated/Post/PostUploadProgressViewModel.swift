import Foundation

/// This class provides a standard view model for accessing the upload progress of
/// a given post (or page).  It provides progress both in pull (by calling `progress()`
/// and push (by using the `progressBlock` property) forms.
///
class PostUploadProgressViewModel {
    private let post: AbstractPost
    private var progressObserverUUID: UUID? = nil

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

    init(for post: AbstractPost) {
        self.post = post
    }

    func progress() -> Float {
        if post.remoteStatus == .pushing {
            return 1.0
        } else {
            return Float(MediaCoordinator.shared.totalProgress(for: post))
        }
    }

    func shouldHideProgressView() -> Bool {
        return !(MediaCoordinator.shared.isUploadingMedia(for: post) || post.remoteStatus == .pushing)
    }
}
