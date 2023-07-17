import UIKit

/// AnimatedImageCache is an image + animated gif data cache used in
/// CachedAnimatedImageView. It should be accessed via the `shared` singleton.
///
final class AnimatedImageCache {

    // MARK: Singleton

    static let shared: AnimatedImageCache = AnimatedImageCache()

    private init() {}

    // MARK: Private fields

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    // MARK: Instance methods

    func cacheData(data: Data, url: URL?) {
        guard let url = url else {
            return
        }
        let key = url.absoluteString + Constants.keyDataSuffix
        MemoryCache.shared.setData(data, forKey: key)
    }

    func cachedData(url: URL?) -> Data? {
        guard let url = url else {
            return nil
        }
        let key = url.absoluteString + Constants.keyDataSuffix
        return MemoryCache.shared.geData(forKey: key)
    }

    func cacheStaticImage(url: URL?, image: UIImage?) {
        guard let url = url, let image = image else {
            return
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        MemoryCache.shared.setImage(image, forKey: key)
    }

    func cachedStaticImage(url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        let key = url.absoluteString + Constants.keyStaticImageSuffix
        return MemoryCache.shared.getImage(forKey: key)
    }

    func animatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((Data, UIImage?) -> Void)?,
                       failure: ((NSError?) -> Void)? ) -> URLSessionTask? {

        if let cachedImageData = cachedData(url: urlRequest.url) {
            success?(cachedImageData, cachedStaticImage(url: urlRequest.url))
            return nil
        }

        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self] (data, response, error) in
            //check if view is still here
            guard let self = self else {
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
                self.cacheData(data: data, url: key)
                self.cacheStaticImage(url: key, image: staticImage)
            }
            success?(data, staticImage)
        })

        task.resume()
        return task
    }
}

// MARK: - Constants

private extension AnimatedImageCache {
    struct Constants {
        static let keyDataSuffix = "_data"
        static let keyStaticImageSuffix = "_static_image"
    }
}
