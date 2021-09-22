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

    func canLoadImageURL(_ requestURL: URL) -> Bool {
        return !requestURL.isFileURL
    }

    func loadImage(for imageURL: URL, size: CGSize, scale: CGFloat, resizeMode: RCTResizeMode, progressHandler: RCTImageLoaderProgressBlock, partialLoadHandler: RCTImageLoaderPartialLoadBlock, completionHandler: @escaping RCTImageLoaderCompletionBlock) -> RCTImageLoaderCancellationBlock? {
        let cacheKey = getCacheKey(for: imageURL, size: size)

        if let image = AnimatedImageCache.shared.cachedStaticImage(url: cacheKey) {
            completionHandler(nil, image)
            return {}
        }

        var finalSize = size
        var finalScale = scale

        if let size = sizeWidthFromURLQueryItem(from: imageURL) {
            finalScale = 1
            let screenScale = UIScreen.main.scale // The provided scale does not always correspond to the UIScreen scale.
            finalSize = CGSize(width: size.width / screenScale, height: size.height / screenScale)
        }

        let task = mediaUtility.downloadImage(from: imageURL, size: finalSize, scale: finalScale, post: post, success: { (image) in
            AnimatedImageCache.shared.cacheStaticImage(url: cacheKey, image: image)
            completionHandler(nil, image)
        }, onFailure: { (error) in
            completionHandler(error, nil)
        })

        return { task.cancel() }
    }

    private func sizeWidthFromURLQueryItem(from url: URL) -> CGSize? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        for item in components?.queryItems ?? [] {
            if item.name == "w",
                let width = Int(item.value ?? "") {
                return CGSize(width: width, height: 0)
            }
        }
        return nil
    }

    private func getCacheKey(for url: URL, size: CGSize) -> URL? {
        guard size != CGSize.zero else {
            return url
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems
        let newQueryItems = (queryItems ?? []) + [URLQueryItem(name: "cachekey", value: "\(size)")]
        components?.queryItems = newQueryItems
        return components?.url
    }

    static func moduleName() -> String! {
        return String(describing: self)
    }

    func loaderPriority() -> Float {
        return 100
    }


}
