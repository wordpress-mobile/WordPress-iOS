import Aztec
import Gridicons


class RevisionPreviewTextViewManager: NSObject {
    var post: AbstractPost?

    private let mediaUtility = EditorMediaUtility()
    private var activeMediaRequests = [ImageDownloaderTask]()

    private enum Constants {
        static let mediaPlaceholderImageSize = CGSize(width: 128, height: 128)

        static let placeholderMediaLink = URL(string: "placeholder://")
        static let placeholderDocumentLink = URL(string: "documentUploading://")
    }
}


extension RevisionPreviewTextViewManager: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        switch attachment {
        case let videoAttachment as VideoAttachment:
            guard let posterURL = videoAttachment.posterURL else {
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

    /* These 3 functions are mandatory implemented but not needed
     * as the TextView is used to display the content with no action on any attachment.
    */
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) { }
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) { }
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) { }
}


private extension RevisionPreviewTextViewManager {
    private func fetchPosterImageFor(videoAttachment: VideoAttachment, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        guard let videoSrcURL = videoAttachment.url,
            videoSrcURL != Constants.placeholderMediaLink,
            videoAttachment.posterURL == nil else {
                onFailure()
                return
        }
        mediaUtility.fetchPosterImage(for: videoSrcURL, onSuccess: onSuccess, onFailure: onFailure)
    }

    private func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        guard let post = post else {
            return
        }

        let receipt = mediaUtility.downloadImage(from: url, post: post, success: success, onFailure: { (_) in failure() })
        activeMediaRequests.append(receipt)
    }
}
