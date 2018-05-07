//
// Previously, we were using FLAnimatedImage to show gifs. (https://github.com/Flipboard/FLAnimatedImage)
// It's a good, battle-tested component written in Obj-c with a good solution for memory usage on big files.
// We decided to look for other alternatives and we got to Gifu. (https://github.com/kaishin/Gifu)
// - It has a similar approach to be memory efficient. Tests showed that is more memory efficient than FLAnimatedImage.
// - It's written in Swift, in a protocol oriented approach. That make it easier to implement it in a Swift code base.
// - It has extra features, like stopping and plying gifs, and a special `prepareForReuse` for table/collection views.
// - It seems to be more active, being updated few months ago, in contrast to a couple of years ago of FLAnimatedImage

import Foundation
import Gifu

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    @objc var currentTask: URLSessionTask?
    var originalURLRequest: URLRequest?

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    override public func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    @objc var isGif: Bool {
        return frameCount != 0
    }

    @objc func setAnimatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: (() -> Void)? ,
                       failure: ((NSError?) -> Void)? ) {

        if let ongoingTask = currentTask {
            ongoingTask.cancel()
        }

        if originalURLRequest != urlRequest {
            image = placeholderImage
        }

        let successBlock: (Data) -> Void = { [weak self] animatedImageData in
            guard let strongSelf = self else {
                return
            }
            strongSelf.animate(data: animatedImageData, success: success)
        }

        originalURLRequest = urlRequest
        currentTask = AnimatedImageCache.shared.animatedImage(urlRequest,
                                                              placeholderImage: placeholderImage,
                                                              success: successBlock,
                                                              failure: failure)
    }

    private func animate(data: Data, success: (() -> Void)?) {
        DispatchQueue.main.async() {
            self.animate(withGIFData: data) {
                success?()
            }
        }
    }

    @objc func prepForReuse() {
        self.prepareForReuse()
    }
}

class AnimatedImageCache {

    static let shared: AnimatedImageCache = AnimatedImageCache()

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate lazy var cache: NSCache<NSURL, NSData> = {
        return NSCache<NSURL, NSData>()
    }()

    func animatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((Data) -> Void)? ,
                       failure: ((NSError?) -> Void)? ) -> URLSessionTask? {

        if  let key = urlRequest.url,
            let animatedImageData = cache.object(forKey: key as NSURL) {

            success?(animatedImageData as Data)
            return nil
        }

        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self](data, response, error) in
            //check if view is still here
            guard let strongSelf = self else {
                return
            }
            // check if there is an error
            if let error = error {
                let nsError = error as NSError
                // task.cancel() triggers an error that we don't want to send to the error handler.
                if nsError.code != NSURLErrorCancelled {
                    failure?(nsError)
                }
                return
            }
            // check if data is here and is animated gif
            guard let data = data else {
                failure?(nil)
                return
            }

            if  let key = urlRequest.url {
                strongSelf.cache.setObject(data as NSData, forKey: key as NSURL)
            }
            success?(data)
        })

        task.resume()
        return task
    }
}
