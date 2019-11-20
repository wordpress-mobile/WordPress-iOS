import Foundation
import Gutenberg

class GutenbergImageLoader: NSObject, RCTImageURLLoader {

    public var post: AbstractPost

    private lazy var mediaUtility: EditorMediaUtility = {
        return EditorMediaUtility()
    }()

    public init(post: AbstractPost) {
        self.post = post
    }

    func canLoadImageURL(_ requestURL: URL!) -> Bool {
        return !requestURL.isFileURL
    }

    func loadImage(for imageURL: URL!, size: CGSize, scale: CGFloat, resizeMode: RCTResizeMode, progressHandler: RCTImageLoaderProgressBlock!, partialLoadHandler: RCTImageLoaderPartialLoadBlock!, completionHandler: RCTImageLoaderCompletionBlock!) -> RCTImageLoaderCancellationBlock! {
        if let image = AnimatedImageCache.shared.cachedStaticImage(url: imageURL) {
            completionHandler(nil, image)
            return {}
        }
        let size = sizeWidthFromURLQueryItem(from: imageURL) ?? size
        let task = mediaUtility.downloadImage(from: imageURL, size: size, scale: 1, post: post, allowPhotonAPI: false, success: { (image) in
            AnimatedImageCache.shared.cacheStaticImage(url: imageURL, image: image)
            completionHandler(nil, image)
        }, onFailure: { (error) in
            completionHandler(error, nil)
        })

        return { task.cancel() }
    }

    func sizeWidthFromURLQueryItem(from url: URL) -> CGSize? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        for item in components?.queryItems ?? [] {
            if item.name == "w",
                let width = Int(item.value ?? "") {
                return CGSize(width: width, height: 0)
            }
        }
        return nil
    }

    static func moduleName() -> String! {
        return String(describing: self)
    }

    func loaderPriority() -> Float {
        return 100
    }


}
