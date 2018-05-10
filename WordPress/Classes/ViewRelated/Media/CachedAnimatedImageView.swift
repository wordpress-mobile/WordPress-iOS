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

@objc public protocol ActivityIndicatorType where Self: UIView {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: ActivityIndicatorType {
}

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    public enum LoadingIndicatorStyle {
        case centered(withSize: CGSize?)
        case fullView
    }

    // MARK: Public fields

    public var gifPlaybackStrategy: GIFPlaybackStrategy = MediumGIFPlaybackStrategy()

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    // MARK: Private fields

    @objc private var currentTask: URLSessionTask?

    private var customLoadingIndicator: ActivityIndicatorType?

    private lazy var defaultLoadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        layoutViewCentered(loadingIndicator, size: nil)
        return loadingIndicator
    }()

    private var loadingIndicator: ActivityIndicatorType {
        guard let custom = customLoadingIndicator else {
            return defaultLoadingIndicator
        }
        return custom
    }

    // MARK: - Public methods

    override public func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    @objc public func setAnimatedImage(_ urlRequest: URLRequest,
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
    @objc public func clean() {
        currentTask?.cancel()
        image = nil
    }

    @objc public func prepForReuse() {
        self.prepareForReuse()
    }

    public func startLoadingAnimation() {
        DispatchQueue.main.async() {
            self.loadingIndicator.startAnimating()
        }
    }

    public func stopLoadingAnimation() {
        DispatchQueue.main.async() {
            self.loadingIndicator.stopAnimating()
        }
    }

    public func addLoadingIndicator(_ loadingIndicator: ActivityIndicatorType, style: LoadingIndicatorStyle) {

        guard let loadingView = loadingIndicator as? UIView else {
            assertionFailure("Loading indicator must be a UIView subclass")
            return
        }

        removeCustomLoadingIndicator()
        customLoadingIndicator = loadingIndicator
        addCustomLoadingIndicator(loadingView, style: style)
    }

    // MARK: - Private methods

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

    private func animate(data: Data, success: (() -> Void)?) {
        DispatchQueue.main.async() {
            self.setFrameBufferCount(self.gifPlaybackStrategy.frameBufferCount)
            self.animate(withGIFData: data) {
                success?()
            }
        }
    }

    // MARK: Loading indicator

    private func removeCustomLoadingIndicator() {
        if let oldLoadingIndicator = customLoadingIndicator as? UIView {
            oldLoadingIndicator.removeFromSuperview()
        }
    }

    private func addCustomLoadingIndicator(_ loadingView: UIView, style: LoadingIndicatorStyle) {
        switch style {
        case .centered(let size):
            layoutViewCentered(loadingView, size: size)
        default:
            layoutViewFullView(loadingView)
        }
    }

    // MARK: Layout

    private func prepareViewForLayout(_ view: UIView) {
        if view.superview == nil {
            addSubview(view)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func layoutViewCentered(_ view: UIView, size: CGSize?) {
        prepareViewForLayout(view)
        var constraints: [NSLayoutConstraint] = [
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        if let size = size {
            constraints.append(view.heightAnchor.constraint(equalToConstant: size.height))
            constraints.append(view.widthAnchor.constraint(equalToConstant: size.width))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func layoutViewFullView(_ view: UIView) {
        prepareViewForLayout(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
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
