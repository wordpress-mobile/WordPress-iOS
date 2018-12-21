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
        guard let videoSrcURL = videoAttachment.url,
            let placeholderURL = URL(string: "placeholder://"),
            videoSrcURL != placeholderURL,
            videoAttachment.posterURL == nil else {
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
     * as the TextView is used to display the content with no action on any attachment.
    */
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) { }
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) { }
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) { }
}


private extension RevisionPreviewTextViewManager {
    private func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        let size = CGSize(width: imageMaxDimension, height: 0)
        let requestURL: URL = url.isFileURL ? url : PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
        let request = URLRequest(url: requestURL)

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
        let size = CGSize(width: 128, height: 128)
        let iconType = getIconType(for: attachment)
        let icon = Gridicon.iconOfType(iconType, withSize: size)
        icon.addAccessibilityForAttachment(attachment)
        return icon
    }

    private func getIconType(for attachment: NSTextAttachment) -> GridiconType {
        guard let url = URL(string: "documentUploading://") else {
            preconditionFailure("Invalid static URL string: documentUploading://")
        }
        switch attachment {
        case let imageAttachment as ImageAttachment:
            return (imageAttachment.url == url) ? .pages : .image
        case _ as VideoAttachment:
            return .video
        default:
            return .attachment
        }
    }
}
