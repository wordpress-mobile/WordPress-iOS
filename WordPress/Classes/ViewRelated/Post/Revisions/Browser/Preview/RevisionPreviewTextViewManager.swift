import Aztec
import Gridicons


class RevisionPreviewTextViewManager: NSObject {
    private var activeMediaRequests = [ImageDownloader.Task]()
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
        return placeholderImage(for: attachment)
    }

    func fetchPosterImageFor(videoAttachment: VideoAttachment, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        guard let videoSrcURL = videoAttachment.url, videoSrcURL != URL(string: "placeholder://")!, videoAttachment.posterURL == nil else {
            onFailure()
            return
        }
        let thumbnailGenerator = MediaVideoExporter(url: videoSrcURL)
        thumbnailGenerator.exportPreviewImageForVideo(atURL: videoSrcURL, imageOptions: nil, onCompletion: { (exportResult) in
            guard let image = UIImage(contentsOfFile: exportResult.url.path) else {
                onFailure()
                return
            }
            DispatchQueue.main.async {
                onSuccess(image)
            }
        }, onError: { (error) in
            DDLogError("Unable to grab frame from video = \(videoSrcURL). Details: \(error.localizedDescription)")
            onFailure()
        })
    }

    /* These 3 functions are mandatory implemented but not needed
     * as the TextView is used to display the content with no action on it.
    */
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {

    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {

    }
}


private extension RevisionPreviewTextViewManager {
    private func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        var requestURL = url
        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        //use height zero to maintain the aspect ratio when fetching
        let size = CGSize(width: imageMaxDimension, height: 0)
        let request: URLRequest
        if url.isFileURL {
            request = URLRequest(url: url)
        }  else {
            // the size that PhotonImageURLHelper expects is points size
            requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        }

        let receipt = ImageDownloader.shared.downloadImage(for: request) { [weak self] (image, error) in
            guard let _ = self else {
                return
            }

            DispatchQueue.main.async {
                guard let image = image else {
                    DDLogError("Unable to download image for attachment with url = \(url). Details: \(String(describing: error?.localizedDescription))")
                    failure()
                    return
                }
                success(image)
            }
        }
        activeMediaRequests.append(receipt)
    }

    private func placeholderImage(for attachment: NSTextAttachment) -> UIImage {
        let url = URL(string: "documentUploading://")!
        let icon: UIImage
        switch attachment {
        case let imageAttachment as ImageAttachment:
            if imageAttachment.url == url {
                icon = Gridicon.iconOfType(.pages, withSize: CGSize(width: 128, height: 128))
            } else {
                icon = Gridicon.iconOfType(.image, withSize: CGSize(width: 128, height: 128))
            }
        case _ as VideoAttachment:
            icon = Gridicon.iconOfType(.video, withSize: CGSize(width: 128, height: 128))
        default:
            icon = Gridicon.iconOfType(.attachment, withSize: CGSize(width: 128, height: 128))
        }

        icon.addAccessibilityForAttachment(attachment)
        return icon
    }
}
