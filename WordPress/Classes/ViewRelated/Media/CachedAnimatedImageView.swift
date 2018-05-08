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

@objc protocol ActivityIndicatorType where Self: UIView  {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: ActivityIndicatorType {
}

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    @objc var currentTask: URLSessionTask?
    var gifPlaybackStrategy: GIFPlaybackStrategy = MediumGIFPlaybackStrategy()

    var customLoadingIndicator: ActivityIndicatorType? {
        didSet {
            if let oldIndicator = oldValue as? UIView {
                oldIndicator.removeFromSuperview()
            }
        }
    }

    private lazy var defaultLoadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        layoutLoadingIndicator(loadingIndicator)
        return loadingIndicator
    }()

    private var loadingIndicator: ActivityIndicatorType {
        guard let custom = customLoadingIndicator else {
            return defaultLoadingIndicator
        }
        if let customView = custom as? UIView, customView.superview == nil {
            layoutLoadingIndicator(customView)
        }
        return custom
    }

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    override public func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    @objc func setAnimatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: (() -> Void)?,
                       failure: ((NSError?) -> Void)?) {

        currentTask?.cancel()
        image = placeholderImage

        if checkCache(urlRequest, success) {
            return
        }

        let successBlock: (Data, UIImage?) -> Void = { [weak self] animatedImageData, staticImage in
            let didVerifyDataSize = self?.gifPlaybackStrategy.verifyDataSize(animatedImageData) ?? true
            if didVerifyDataSize {
                self?.animate(data: animatedImageData, success: success)
            } else {
                DispatchQueue.main.async() {
                    self?.image = staticImage
                    success?()
                }
            }
        }

        currentTask = AnimatedImageCache.shared.animatedImage(urlRequest,
                                                              placeholderImage: placeholderImage,
                                                              success: successBlock,
                                                              failure: failure)
    }

    /// Clean the image view from previous images and ongoing data tasks.
    ///
    @objc func clean() {
        currentTask?.cancel()
        image = nil
    }

    @objc func prepForReuse() {
        self.prepareForReuse()
    }

    func startLoadingAnimation() {
        DispatchQueue.main.async() {
            self.loadingIndicator.startAnimating()
        }
    }

    func stopLoadingAnimation() {
        DispatchQueue.main.async() {
            self.loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Helpers

    private func animate(data: Data, success: (() -> Void)?) {
        DispatchQueue.main.async() {
            self.setFrameBufferCount(self.gifPlaybackStrategy.frameBufferCount)
            self.animate(withGIFData: data) {
                success?()
            }
        }
    }

    private func layoutLoadingIndicator(_ loadingIndicator: UIView) {
        addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    private func checkCache(_ urlRequest: URLRequest, _ success: (() -> Void)?) -> Bool {
        if let cachedData = AnimatedImageCache.shared.cachedData(url: urlRequest.url) {
            // Always attempt to load momentary image to show while gif is loading to avoid flashing.
            if let cachedStaticImage = AnimatedImageCache.shared.cachedStaticImage(url: urlRequest.url) {
                image = cachedStaticImage
            } else {
                let staticImage = UIImage(data: cachedData)
                image = staticImage
                AnimatedImageCache.shared.cacheStaticImage(url: urlRequest.url, image: staticImage)
            }

            if gifPlaybackStrategy.verifyDataSize(cachedData) {
                animate(data: cachedData, success: success)
            } else {
                success?()
            }

            return true
        }

        return false
    }

}

// MARK: - AnimatedImageCache

class AnimatedImageCache {

    static let shared: AnimatedImageCache = AnimatedImageCache()

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate lazy var cache: NSCache<AnyObject, AnyObject> = {
        return NSCache<AnyObject, AnyObject>()
    }()

    func cachedData(url: URL?) -> Data? {
        guard let key = url else {
            return nil
        }
        return cache.object(forKey: key as AnyObject) as? Data
    }

    func cacheStaticImage(url: URL?, image: UIImage?) {
        guard let url = url,
            let image = image else {
                return
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        cache.setObject(image as AnyObject, forKey: key as AnyObject)
    }

    func cachedStaticImage(url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        return cache.object(forKey: key as AnyObject) as? UIImage
    }

    func animatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((Data, UIImage?) -> Void)? ,
                       failure: ((NSError?) -> Void)? ) -> URLSessionTask? {

        if let cachedImageData = cachedData(url: urlRequest.url) {
            success?(cachedImageData, cachedStaticImage(url: urlRequest.url))
            return nil
        }

        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self] (data, response, error) in
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

            let staticImage = UIImage(data: data)
            if let key = urlRequest.url {
                strongSelf.cache.setObject(data as NSData, forKey: key as NSURL)

                // Creating a static image from GIF data is an expensive op, so let's try to do it once...
                let imageKey = key.absoluteString + Constants.keyStaticImageSuffix
                strongSelf.cache.setObject(staticImage as AnyObject, forKey: imageKey as AnyObject)
            }
            success?(data, staticImage)
        })

        task.resume()
        return task
    }
}

// MARK: - Constants

extension AnimatedImageCache {
    struct Constants {
        static let keyStaticImageSuffix = "_static_image"
    }
}
