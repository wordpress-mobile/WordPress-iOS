import Aztec

class AztecAttachmentDelegate: TextViewAttachmentDelegate {
    private let post: AbstractPost
    private var activeMediaRequests = [ImageDownloaderTask]()
    private let mediaUtility = EditorMediaUtility()

    init(post: AbstractPost) {
        self.post = post
    }

    func cancelAllPendingMediaRequests() {
        for receipt in activeMediaRequests {
            receipt.cancel()
        }
        activeMediaRequests.removeAll()
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        switch attachment {
        case let videoAttachment as VideoAttachment:
            guard let posterURL = videoAttachment.posterURL else {
                // Let's get a frame from the video directly
                fetchPosterImageFor(videoAttachment: videoAttachment, onSuccess: success, onFailure: failure)
                return
            }
            downloadImage(from: posterURL, success: success, onFailure: failure)
        case is ImageAttachment:
            downloadImage(from: url, success: success, onFailure: failure)
        default:
            failure()
        }
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return mediaUtility.placeholderImage(for: attachment, size: Constants.mediaPlaceholderImageSize, tintColor: textView.textColor)
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        textView.setNeedsDisplay()
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }

    func fetchPosterImageFor(videoAttachment: VideoAttachment, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        guard let videoSrcURL = videoAttachment.url, videoSrcURL != Constants.placeholderMediaLink, videoAttachment.posterURL == nil else {
            onFailure()
            return
        }
        mediaUtility.fetchPosterImage(for: videoSrcURL, onSuccess: onSuccess, onFailure: onFailure)
    }

    func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        let receipt = mediaUtility.downloadImage(from: url, post: post, success: success, onFailure: { (_) in failure()})
        activeMediaRequests.append(receipt)
    }
}

private struct Constants {
    static let placeholderMediaLink = URL(string: "placeholder://")!
    static let mediaPlaceholderImageSize = CGSize(width: 128, height: 128)
}
