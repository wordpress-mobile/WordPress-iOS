import AutomatticTracks
import Aztec
import Gridicons

final class AuthenticatedImageDownload: AsyncOperation {
    enum DownloadError: Error {
        case blogNotFound
    }

    let url: URL
    let blogObjectID: NSManagedObjectID
    private let callbackQueue: DispatchQueue
    private let onSuccess: (UIImage) -> ()
    private let onFailure: (Error) -> ()

    init(url: URL, blogObjectID: NSManagedObjectID, callbackQueue: DispatchQueue, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping (Error) -> ()) {
        assert(!blogObjectID.isTemporaryID)
        self.url = url
        self.blogObjectID = blogObjectID
        self.callbackQueue = callbackQueue
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    override func main() {
        let result = ContextManager.shared.performQuery { context in
            Result {
                // Can't fetch the blog using a temporary ID. This check is added as an attempt to prevent this crash:
                // https://github.com/wordpress-mobile/WordPress-iOS/issues/20630
                guard !self.blogObjectID.isTemporaryID else {
                    throw DownloadError.blogNotFound
                }

                let blog = try context.existingObject(with: self.blogObjectID) as! Blog
                return MediaHost(with: blog) { error in
                    // We'll log the error, so we know it's there, but we won't halt execution.
                    WordPressAppDelegate.crashLogging?.logError(error)
                }
            }
        }

        let host: MediaHost
        do {
            host = try result.get()
        } catch {
            self.state = .isFinished
            self.callbackQueue.async {
                self.onFailure(error)
            }
            return
        }

        let mediaRequestAuthenticator = MediaRequestAuthenticator()
        mediaRequestAuthenticator.authenticatedRequest(
            for: url,
            from: host,
            onComplete: { request in
                ImageDownloader.shared.downloadImage(for: request) { (image, error) in
                    self.state = .isFinished

                    self.callbackQueue.async {
                        guard let image = image else {
                            DDLogError("Unable to download image for attachment with url = \(String(describing: request.url)). Details: \(String(describing: error?.localizedDescription))")
                            if let error = error {
                                self.onFailure(error)
                            } else {
                                self.onFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
                            }

                            return
                        }

                        self.onSuccess(image)
                    }
                }
            },
            onFailure: { error in
                self.state = .isFinished
                self.callbackQueue.async {
                    self.onFailure(error)
                }
            }
        )
    }
}

class EditorMediaUtility {
    private static let InternalInconsistencyError = NSError(domain: NSExceptionName.internalInconsistencyException.rawValue, code: 0)

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
        if let color = tintColor {
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


    func downloadImage(
        from url: URL,
        post: AbstractPost,
        success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping (Error) -> Void) -> ImageDownloaderTask {

        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        //use height zero to maintain the aspect ratio when fetching
        let size = CGSize(width: imageMaxDimension, height: 0)
        let scale = UIScreen.main.scale

        return downloadImage(from: url, size: size, scale: scale, post: post, success: success, onFailure: failure)
    }

    func downloadImage(
        from url: URL,
        size requestSize: CGSize,
        scale: CGFloat,
        post: AbstractPost,
        success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping (Error) -> Void
    ) -> ImageDownloaderTask {

        let imageMaxDimension = max(requestSize.width, requestSize.height)
        //use height zero to maintain the aspect ratio when fetching
        var size = CGSize(width: imageMaxDimension, height: 0)
        let (requestURL, blogObjectID) = workaroundCoreDataConcurrencyIssue(accessing: post) {
            let requestURL: URL
            if url.isFileURL {
                requestURL = url
            } else if post.isPrivateAtWPCom() && url.isHostedAtWPCom {
                // private wpcom image needs special handling.
                // the size that WPImageHelper expects is pixel size
                size.width = size.width * scale
                requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: url)
            } else if !post.blog.isHostedAtWPcom && post.blog.isBasicAuthCredentialStored() {
                size.width = size.width * scale
                requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: url)
            } else {
                // the size that PhotonImageURLHelper expects is points size
                requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
            }
            return (requestURL, post.blog.objectID)
        }

        let imageDownload = AuthenticatedImageDownload(
            url: requestURL,
            blogObjectID: blogObjectID,
            callbackQueue: .main,
            onSuccess: success,
            onFailure: failure)

        imageDownload.start()
        return imageDownload
    }

    static func fetchRemoteVideoURL(for media: Media, in post: AbstractPost, withToken: Bool = false, completion: @escaping ( Result<(URL), Error> ) -> Void) {
        // Return the attachment url it it's not a VideoPress video
        if media.videopressGUID == nil {
            guard let videoURLString = media.remoteURL, let videoURL = URL(string: videoURLString) else {
                DDLogError("Unable to find remote video URL for video with upload ID = \(media.uploadID).")
                completion(Result.failure(InternalInconsistencyError))
                return
            }
            completion(Result.success(videoURL))
        }
        else {
            fetchVideoPressMetadata(for: media, in: post) { result in
                switch result {
                case .success((let metadata)):
                    guard let originalURL = metadata.originalURL else {
                        DDLogError("Failed getting original URL for media with upload ID: \(media.uploadID)")
                        completion(Result.failure(InternalInconsistencyError))
                        return
                    }
                    if withToken {
                        completion(Result.success(metadata.getURLWithToken(url: originalURL) ?? originalURL))
                    }
                    else {
                        completion(Result.success(originalURL))
                    }
                case .failure(let error):
                    completion(Result.failure(error))
                }
            }
        }
    }

    static func fetchVideoPressMetadata(for media: Media, in post: AbstractPost, completion: @escaping ( Result<(RemoteVideoPressVideo), Error> ) -> Void) {
        guard let videoPressID = media.videopressGUID else {
            DDLogError("Unable to find metadata for video with upload ID = \(media.uploadID).")
            completion(Result.failure(InternalInconsistencyError))
            return
        }

        let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        mediaService.getMetadataFromVideoPressID(videoPressID, in: post.blog, success: { (metadata) in
            completion(Result.success(metadata))
        }, failure: { (error) in
            DDLogError("Unable to find metadata for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            completion(Result.failure(error))
        })
    }
}
