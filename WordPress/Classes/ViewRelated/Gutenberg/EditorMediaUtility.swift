import Aztec
import Gridicons

class EditorMediaUtility {

    private struct Constants {
        static let placeholderDocumentLink = URL(string: "documentUploading://")!
    }

    func placeholderImage(for attachment: NSTextAttachment, size: CGSize, tintColor: UIColor?) -> UIImage {
        var icon: UIImage
        switch attachment {
        case let imageAttachment as ImageAttachment:
            if imageAttachment.url == Constants.placeholderDocumentLink {
                icon = .gridicon(.pages, size: size)
            } else {
                icon = .gridicon(.image, size: size)
            }
        case _ as VideoAttachment:
            icon = .gridicon(.video, size: size)
        default:
            icon = .gridicon(.attachment, size: size)
        }
        if #available(iOS 13.0, *), let color = tintColor {
            icon = icon.withTintColor(color)
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

    static func fetchRemoteVideoURL(for media: Media, in post: AbstractPost, completion: @escaping ( Result<(videoURL: URL, posterURL: URL?), Error> ) -> Void) {
        guard let videoPressID = media.videopressGUID else {
            //the site can be a self-hosted site if there's no videopressGUID
            if let videoURLString = media.remoteURL,
                let videoURL = URL(string: videoURLString) {
                completion(Result.success((videoURL: videoURL, posterURL: nil)))
            } else {
                DDLogError("Unable to find remote video URL for video with upload ID = \(media.uploadID).")
                completion(Result.failure(NSError()))
            }
            return
        }
        let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        mediaService.getMediaURL(fromVideoPressID: videoPressID, in: post.blog, success: { (videoURLString, posterURLString) in
            guard let videoURL = URL(string: videoURLString) else {
                completion(Result.failure(NSError()))
                return
            }
            var posterURL: URL?
            if let validPosterURLString = posterURLString, let url = URL(string: validPosterURLString) {
                posterURL = url
            }
            completion(Result.success((videoURL: videoURL, posterURL: posterURL)))
        }, failure: { (error) in
            DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            completion(Result.failure(error))
        })
    }
}
