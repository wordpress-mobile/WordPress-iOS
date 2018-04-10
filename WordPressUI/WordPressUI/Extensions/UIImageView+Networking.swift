import Foundation


public extension UIImageView {

    /// Downloads an image and updates the current UIImageView Instance.
    ///
    /// - Parameters:
    ///     -   url: The target Image's URL.
    ///     -   placeholderImage: Image to be displayed while the actual asset gets downloaded.
    ///     -   pointSize: *Maximum* allowed size. if the actual asset exceeds this size, we'll shrink it down.
    ///
    public func downloadResizedImage(from url: URL?, placeholderImage: UIImage? = nil, pointSize: CGSize) {
        downloadImage(from: url, placeholderImage: placeholderImage, success: { [weak self] image in
            guard image.size.height > pointSize.height || image.size.width > pointSize.width else {
                self?.image = image
                return
            }

            self?.image = image.resizedImage(with: .scaleAspectFit, bounds: pointSize, interpolationQuality: .high)
        })
    }

    /// Downloads an image and updates the current UIImageView Instance.
    ///
    /// - Parameters:
    ///     -   url: The URL of the target image
    ///     -   placeholderImage: Image to be displayed while the actual asset gets downloaded.
    ///     -   success: Closure to be executed on success.
    ///     -   failure: Closure to be executed upon failure.
    ///
    public func downloadImage(from url: URL?, placeholderImage: UIImage? = nil, success: ((UIImage) -> ())? = nil, failure: ((Error?) -> ())? = nil) {
        let internalOnSuccess = { [weak self] (image: UIImage) in
            self?.image = image
            success?(image)
        }

        if let cachedImage = Downloader.cache.object(forKey: url as AnyObject) as? UIImage {
            internalOnSuccess(cachedImage)
            return
        }

        // Ideally speaking, this method should *not* receive an Optional URL. But we're doing so, for convenience.
        // If the actual URL was nil, at least we set the Placeholder Image. Capicci?
        //
        guard let url = url, url != downloadURL else {
            return
        }

        downloadURL = url

        if let placeholderImage = placeholderImage {
            image = placeholderImage
        }

        let request = self.request(for: url)

        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                failure?(error)
                return
            }

            DispatchQueue.main.async {
                Downloader.cache.setObject(image, forKey: url as AnyObject)

                if response?.url == self?.downloadURL {
                    internalOnSuccess(image)
                }

                self?.downloadTask = nil
            }
        })

        downloadTask?.cancel()
        downloadTask = task
        task.resume()
    }


    /// Overrides the cached UIImage, for a given URL. This is useful for whenever we've just updated a remote resource,
    /// and we need to prevent returning the (old) cached entry.
    ///
    public func overrideImageCache(for url: URL, with image: UIImage) {
        Downloader.cache.setObject(image, forKey: url as AnyObject)

        // Remove all cached responses - removing an individual response does not work since iOS 7.
        // This feels hacky to do but what else can we do...
        //
        // Update: Years have gone by (iOS 11 era). Still broken. Still ashamed about this. Thank you, Apple.
        //
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
    }


    /// Returns a URLRequest for an image, hosted at the specified URL.
    ///
    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return request
    }


    /// Stores the Image's remote URL, if any.
    ///
    private var downloadURL: URL? {
        get {
            return objc_getAssociatedObject(self, &Downloader.urlKey) as? URL
        }
        set {
            objc_setAssociatedObject(self, &Downloader.urlKey, newValue as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


    /// Stores the current DataTask, in charge of downloading the remote Image.
    ///
    private var downloadTask: URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, &Downloader.taskKey) as? URLSessionDataTask
        }
        set {
            objc_setAssociatedObject(self, &Downloader.taskKey, newValue as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


    /// Private helper structure
    ///
    private struct Downloader {

        /// Stores all of the previously downloaded images.
        ///
        static let cache = NSCache<AnyObject, AnyObject>()

        /// Key used to associate the current URL.
        ///
        static var urlKey = "urlKey"

        /// Key used to associate a Download task to the current instance.
        ///
        static var taskKey = "downloadTaskKey"
    }
}
