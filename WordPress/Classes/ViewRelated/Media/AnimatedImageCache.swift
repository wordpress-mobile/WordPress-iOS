import Foundation

/// AnimatedImageCache is an image + animated gif data cache used in
/// CachedAnimatedImageView. It should be accessed via the `shared` singleton.
///
class AnimatedImageCache {

    // MARK: Singleton

    static let shared: AnimatedImageCache = AnimatedImageCache()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(AnimatedImageCache.handleMemoryWarning), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private fields

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate static let cache = NSCache<AnyObject, AnyObject>()

    // MARK: Instance methods

    @objc func handleMemoryWarning() {
        clearCache()
    }

    func clearCache() {
        AnimatedImageCache.cache.removeAllObjects()
    }

    func cachedData(url: URL?) -> Data? {
        guard let key = url else {
            return nil
        }
        return AnimatedImageCache.cache.object(forKey: key as AnyObject) as? Data
    }

    func cacheStaticImage(url: URL?, image: UIImage?) {
        guard let url = url,
            let image = image else {
                return
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        AnimatedImageCache.cache.setObject(image as AnyObject, forKey: key as AnyObject)
    }

    func cachedStaticImage(url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        return AnimatedImageCache.cache.object(forKey: key as AnyObject) as? UIImage
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
            guard let _ = self else {
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
                AnimatedImageCache.cache.setObject(data as NSData, forKey: key as NSURL)

                // Creating a static image from GIF data is an expensive op, so let's try to do it once...
                let imageKey = key.absoluteString + Constants.keyStaticImageSuffix
                AnimatedImageCache.cache.setObject(staticImage as AnyObject, forKey: imageKey as AnyObject)
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
