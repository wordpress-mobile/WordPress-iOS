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
    ///     -   success: Closure to be executed on success. If it's nil, we'll simply update `self.image`
    ///     -   failure: Closure to be executed upon failure.
    ///
    public func downloadImage(from url: URL?, placeholderImage: UIImage? = nil, success: ((UIImage) -> ())? = nil, failure: ((Error?) -> ())? = nil) {
        // By default, onSuccess we just set the image instance
        let defaultOnSuccess = { [weak self] (image: UIImage) in
            self?.image = image
        }

        let internalOnSuccess = success ?? defaultOnSuccess

        // Placeholder?
        if let placeholderImage = placeholderImage {
            image = placeholderImage
        }

        // Ideally speaking, this method should *not* receive an Optional URL. But we're doing so, for convenience.
        // If the actual URL was nil, at least we set the Placeholder Image. Capicci?
        //
        guard let url = url else {
            return
        }

        // Hit the cache
        if let cachedImage = Downloader.cache.object(forKey: url as AnyObject) as? UIImage {
            internalOnSuccess(cachedImage)
            return
        }

        // Cancel any previous OP's
        downloadTask?.cancel()
        downloadTask = nil

        // Hit the Backend
        let request = self.request(for: url)

        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                failure?(error)
                return
            }

            DispatchQueue.main.async {
                // Update the Cache
                Downloader.cache.setObject(image, forKey: url as AnyObject)
                internalOnSuccess(image)

                // Cleanup
                self?.downloadTask = nil
            }
        })

        downloadTask = task
        task.resume()
    }


    /// Returns a URLRequest for an image, hosted at the specified URL.
    ///
    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return request
    }


    /// Stores the current DataTask, in charge of downloading the remote Image
    ///
    private var downloadTask: URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, Downloader.taskKey) as? URLSessionDataTask
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, Downloader.taskKey, newValue, policy)
        }
    }


    /// Private helper structure
    ///
    private struct Downloader {

        /// Stores all of the previously downloaded images
        ///
        static let cache = NSCache<AnyObject, AnyObject>()

        /// Key used to associate a Download task to the current instance
        ///
        static let taskKey = "downloadTaskKey"
    }
}
