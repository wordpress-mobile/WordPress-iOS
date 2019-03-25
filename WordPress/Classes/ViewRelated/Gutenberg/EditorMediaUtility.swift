import Aztec
import Gridicons

class EditorMediaUtility {

    private struct Constants {
        static let placeholderDocumentLink = URL(string: "documentUploading://")!
    }

    func placeholderImage(for attachment: NSTextAttachment, size: CGSize) -> UIImage {
        let icon: UIImage
        switch attachment {
        case let imageAttachment as ImageAttachment:
            if imageAttachment.url == Constants.placeholderDocumentLink {
                icon = Gridicon.iconOfType(.pages, withSize: size)
            } else {
                icon = Gridicon.iconOfType(.image, withSize: size)
            }
        case _ as VideoAttachment:
            icon = Gridicon.iconOfType(.video, withSize: size)
        default:
            icon = Gridicon.iconOfType(.attachment, withSize: size)
        }

        icon.addAccessibilityForAttachment(attachment)
        return icon
    }

    func fetchPosterImage(for sourceURL: URL, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        let thumbnailGenerator = MediaVideoExporter(url: sourceURL)
        thumbnailGenerator.exportPreviewImageForVideo(atURL: sourceURL, imageOptions: nil, onCompletion: { (exportResult) in
            guard let image = UIImage(contentsOfFile: exportResult.url.path) else {
                onFailure()
                return
            }
            DispatchQueue.main.async {
                onSuccess(image)
            }
        }, onError: { (error) in
            DDLogError("Unable to grab frame from video = \(sourceURL). Details: \(error.localizedDescription)")
            onFailure()
        })
    }


    func downloadImage(from url: URL, post: AbstractPost, success: @escaping (UIImage) -> Void, onFailure failure: @escaping (Error) -> Void) -> ImageDownloader.Task {
        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        //use height zero to maintain the aspect ratio when fetching
        let size = CGSize(width: imageMaxDimension, height: 0)
        let scale = UIScreen.main.scale
        return downloadImage(from: url, size: size, scale: scale, post: post, success: success, onFailure: failure)
    }

    func downloadImage(from url: URL, size requestSize: CGSize, scale: CGFloat, post: AbstractPost, success: @escaping (UIImage) -> Void, onFailure failure: @escaping (Error) -> Void) -> ImageDownloader.Task {
        var requestURL = url
        let imageMaxDimension = max(requestSize.width, requestSize.height)
        //use height zero to maintain the aspect ratio when fetching
        var size = CGSize(width: imageMaxDimension, height: 0)
        let request: URLRequest

        if url.isFileURL {
            request = URLRequest(url: url)
        } else if post.blog.isPrivate() && PrivateSiteURLProtocol.urlGoes(toWPComSite: url) {
            // private wpcom image needs special handling.
            // the size that WPImageHelper expects is pixel size
            size.width = size.width * scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: requestURL)
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: requestURL)
        } else if !post.blog.isHostedAtWPcom && post.blog.isBasicAuthCredentialStored() {
            size.width = size.width * scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        } else {
            // the size that PhotonImageURLHelper expects is points size
            requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        }

        return ImageDownloader.shared.downloadImage(for: request) { [weak self] (image, error) in
            guard let _ = self else {
                return
            }

            DispatchQueue.main.async {
                guard let image = image else {
                    DDLogError("Unable to download image for attachment with url = \(url). Details: \(String(describing: error?.localizedDescription))")
                    if let error = error {
                        failure(error)
                    } else {
                        failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
                    }
                    return
                }

                success(image)
            }
        }
    }
}
