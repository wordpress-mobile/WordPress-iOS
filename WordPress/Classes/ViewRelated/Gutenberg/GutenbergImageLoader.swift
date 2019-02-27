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
        let task = mediaUtility.downloadImage(from: imageURL, size: size, scale: scale, post: post, success: { (image) in
            completionHandler(nil, image)
        }, onFailure: { (error) in
            completionHandler(error, nil)
        })

        return { () in task.cancel() }
    }

    static func moduleName() -> String! {
        return String(describing: self)
    }

    func loaderPriority() -> Float {
        return 100
    }


}
